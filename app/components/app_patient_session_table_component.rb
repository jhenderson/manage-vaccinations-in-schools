# frozen_string_literal: true

class AppPatientSessionTableComponent < ViewComponent::Base
  erb_template <<-ERB
    <% if patient_sessions.any? %>
      <%= govuk_table(html_attributes: { class: "nhsuk-table-responsive" }) do |table| %>
        <% table.with_head do |head| %>
          <% head.with_row do |row| %>
            <% row.with_cell(text: "Location") %>
            <% row.with_cell(text: "Programme") %>
            <% row.with_cell(text: "Academic year") %>
          <% end %>
        <% end %>
    
        <% table.with_body do |body| %>
          <% patient_sessions.each do |patient_session| %>
            <% patient_session.programmes.each do |programme| %>
              <% body.with_row do |row| %>
                <% row.with_cell do %>
                  <span class="nhsuk-table-responsive__heading">Location</span>
                  <%= link_to patient_session.session.location.name,
                              session_patient_programme_path(patient_session.session, patient_session.patient, programme) %>
                <% end %>
      
                <% row.with_cell do %>
                  <span class="nhsuk-table-responsive__heading">Programme</span>
                  <%= programme.name %>
                <% end %>
      
                <% row.with_cell do %>
                  <span class="nhsuk-table-responsive__heading">Academic year</span>
                  <%= helpers.session_academic_year(patient_session.session) %>
                <% end %>
              <% end %>
            <% end %>
          <% end %>
        <% end %>
      <% end %>
    <% else %>
      <p class="nhsuk-body">No sessions</p>
    <% end %>
  ERB

  def initialize(patient_sessions)
    super

    @patient_sessions = patient_sessions
  end

  private

  attr_reader :patient_sessions
end
