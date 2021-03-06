class AccountSetup::BusinessesController < ApplicationController
  include AccountSetupHelper

  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_your_inbox")
  end

  before_filter :validate_user_type
  before_filter :validate_current_step
  before_filter :update_business_account_and_setup_vars

  PROGRESSES = {
    account_setup_step: 1,
    current: 1,
    items: {
      "#{Person::ACCOUNT_SETUP_STEPS[:"1"]}": I18n.t("account_setup.business.steps.business_name"),
      "#{Person::ACCOUNT_SETUP_STEPS[:"2"]}": I18n.t("account_setup.business.steps.business_location"),
      "#{Person::ACCOUNT_SETUP_STEPS[:"3"]}": I18n.t("account_setup.business.steps.business_skills"),
      "#{Person::ACCOUNT_SETUP_STEPS[:"4"]}": I18n.t("account_setup.business.steps.business_description"),
      "#{Person::ACCOUNT_SETUP_STEPS[:"5"]}": I18n.t("account_setup.business.steps.business_promo_pics")
    }
  }
  
  def new_step1
    @progresses[:current] = 1
  end

  def new_step2
    @progresses[:current] = 2
    @countries = ISO3166::Country.all.sort_by!{ |c| c.name.downcase }
  end

  def new_step3
    @progresses[:current] = 3
  end

  def new_step4
    @progresses[:current] = 4
  end

  def new_step5
    @progresses[:current] = 5
  end

  def new_step6
    @title = I18n.t("account_setup.business.step6.congratulations")
  end

  private

  def update_business_account_and_setup_vars
    @person = Business.find(@current_user)
    @progresses = PROGRESSES
    @title = I18n.t("account_setup.register_as_business")

    if request.params["_method"] == "put" && request.method == "POST"
      @person.user_type = Business::PROP_NAME
      @person.account_setup_step = @step_to_update_to if @step_to_update_to > @person.account_setup_step
      unless params[:business]
        redirect_to :back, flash: {alert: "Please recheck all fields."} and return

      end
      safe_params = params.require(:business).permit(:overall_name, :image, :description, 
                                                     locations_attributes: [:id, :country, :city, :postal_code, :distance_limit, :distance_limit_unit], 
                                                     images_attributes: [:id, :image, :_destroy],
                                                     skills_attributes: [:id, :category_id, :years_of_experience])

      # if safe_params[:locations_attributes]
      #   safe_params[:locations_attributes] = [safe_params[:locations_attributes]]
      # end

      unless @person.update_attributes(safe_params)
        redirect_to business_account_setup_step1_path, flash: {notice: "Please recheck all fields."}
      end
    end

    @progresses[:account_setup_step] = @person.account_setup_step
  end

  def validate_user_type
    if @current_user.user_type == Worker::PROP_NAME || @current_user.user_type == Buyer::PROP_NAME
      redirect_to homepage_index_path, flash: { notice: "This section is only accessible by (potential)business users." }
    end
  end

  def validate_current_step
    # No to validate first step
    # If user skips step 1 and trys to save step2(which sends data to step3) it will fail either way
    if params[:action] == "new_step2"
      @step_to_update_to = Person::ACCOUNT_SETUP_STEPS[:"2"]
    elsif params[:action] == "new_step3"
      redirect_to business_account_setup_step1_path if @current_user.account_setup_step < Person::ACCOUNT_SETUP_STEPS[:"2"]
      @step_to_update_to = Person::ACCOUNT_SETUP_STEPS[:"3"]
    elsif params[:action] == "new_step4"
      redirect_to business_account_setup_step1_path if @current_user.account_setup_step < Person::ACCOUNT_SETUP_STEPS[:"3"]
      @step_to_update_to = Person::ACCOUNT_SETUP_STEPS[:"4"]
    elsif params[:action] == "new_step5"
      redirect_to business_account_setup_step1_path if @current_user.account_setup_step < Person::ACCOUNT_SETUP_STEPS[:"4"]
      @step_to_update_to = Person::ACCOUNT_SETUP_STEPS[:"5"]
    elsif params[:action] == "new_step6"
      redirect_to business_account_setup_step1_path if @current_user.account_setup_step != Person::ACCOUNT_SETUP_STEPS[:"5"] && 
                                                      @current_user.account_setup_step != Person::ACCOUNT_SETUP_STEPS[:"6"]
      @step_to_update_to = Person::ACCOUNT_SETUP_STEPS[:"6"]
    end
  end
end
