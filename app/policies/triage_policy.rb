# frozen_string_literal: true

class TriagePolicy < ApplicationPolicy
  def create?
    user.is_nurse?
  end

  def update?
    user.is_nurse?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organisation: user.selected_organisation)
    end
  end
end
