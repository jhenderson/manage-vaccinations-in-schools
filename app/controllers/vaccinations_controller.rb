class VaccinationsController < ApplicationController
  before_action :set_campaign
  before_action :set_child

  def index
    @children = @campaign.children
  end

  def show
  end

  def record
    @child.update!(seen: "Vaccinated")
    redirect_to confirmation_campaign_vaccination_path(@campaign, @child)
  end

  def confirmation
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end

  def set_child
    @child = Child.find(params[:id]) if params.key?(:id)
  end
end
