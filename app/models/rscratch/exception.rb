module Rscratch
  class Exception < ActiveRecord::Base
    
    if Rails::VERSION::MAJOR == 3
      attr_accessible :action, :app_environment, :controller, :exception, :message, :new_occurance_count, :total_occurance_count, :status, :is_ignored
    end
    
    STATUS = %w(new under_development resolved)

    ### => Model Relations
    has_many :exception_logs, :dependent => :destroy

    ### => Model Validations
    validates :exception       , presence: true
    validates :message         , presence: true
    validates :controller      , presence: true
    validates :action          , presence: true
    validates :app_environment , presence: true
    validates :status          , presence: true, :inclusion => {:in => STATUS}
                      
    ### => Model Scopes
    scope :by_exception, lambda {|exc|where(["exception=?", exc])}                      
    scope :by_message, lambda {|msg|where(["message=?", msg])}                      
    scope :by_controller, lambda {|con|where(["controller=?", con])}                      
    scope :by_action, lambda {|act|where(["action=?", act])}                      
    scope :by_environment, lambda {|env|where(["app_environment=?", env])}   
    scope :by_status, lambda {|status|where(["status=?", status])}   

    ### => Model Callbacks
    before_validation :set_default_attributes

    # => Dynamic methods for exception statuses
    STATUS.each do |status|
      define_method "#{status}?" do
        self.status == status
      end
    end

    # Log an exception
    def self.log(_exception,_request) 
      _exc = self.find_or_create(_exception,_request.filtered_parameters["controller"].camelize,_request.filtered_parameters["action"],Rails.env.camelize)
      if _exc.is_ignored == false
        @log = ExceptionLog.new
        @log.set_attributes_for _exception,_request
        _exc.exception_logs << @log 
      else
        @log = _exc.exception_logs.last
      end
      return {:exception_id => _exc.id, :log_id => @log.id, :log_url => "/rscratch/exception_logs/#{@log.id}"}
    end

    # Log unique exceptions
    def self.find_or_create exc,_controller,_action,_env              
      _excp = Exception.by_exception(exc.class).by_message(exc.message).by_controller(_controller).by_action(_action).by_environment(_env)
      if _excp.present?
        return _excp.first
      else
        _excp = Exception.new
        _excp.set_attributes_for exc, _controller, _action, _env
        _excp.save!
        _excp
      end
    end

    # Sets Exception instance attributes.
    def set_attributes_for _exception, _controller, _action, _env
      self.exception = _exception.class
      self.message = _exception.message
      self.controller = _controller
      self.action = _action
      self.app_environment = _env
    end
    
    # Setting new default attributes
    def set_default_attributes
      self.status = "new"
    end    
    
    def resolve!
      update_attribute(:status, 'resolved')
      self.exception_logs.last.resolve!
      reset_counter!
    end
    
    def ignored?
      self.is_ignored == true
    end
    
    def dont_ignore!
      update_attribute(:is_ignored, false)
    end

    def ignore!
      update_attribute(:is_ignored, true)
    end

    def toggle_ignore!
      ignored? ? dont_ignore! : ignore!
    end

    def reset_counter!
      update_attribute(:new_occurance_count, 0)
    end
  end
end
