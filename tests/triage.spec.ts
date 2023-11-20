import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

// Needs state transitions to be added to controller actions
test("Triage", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();
  await when_i_go_to_the_triage_page();

  // Triage - start triage but without outcome
  await when_i_click_on_a_patient();
  await and_i_enter_a_note_and_save_triage();
  await then_the_patient_should_still_be_in_triage();

  // Triage - ready to vaccinate
  await when_i_click_on_a_patient();
  await and_i_enter_a_note_and_select_ready_to_vaccinate();
  await and_i_click_on_the_triage_complete_tab();
  await then_the_patient_should_be_in_ready_to_vaccinate();

  await when_i_click_on_a_patient();
  await then_i_should_see_the_triage_details();

  // Triage - not ready to vaccinate
  await given_i_click_on_back();
  await when_i_click_on_the_needs_triage_tab();
  await and_i_click_on_another_patient();
  await and_i_enter_a_note_and_select_do_not_vaccinate();
  await then_i_should_be_back_on_the_needs_triage_tab();
  await and_i_should_not_see_the_other_patient();

  await when_i_click_on_the_triage_complete_tab();
  await then_i_should_see_the_other_patient();

  await when_i_click_on_the_other_patient();
  await then_i_should_see_their_do_not_vaccinate_status();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_triage_page() {
  await p.goto("/sessions/1/triage");
}

async function when_i_click_on_a_patient() {
  await p.getByRole("link", { name: "Caridad Sipes" }).click();
}

async function and_i_enter_a_note_and_save_triage() {
  await p.getByLabel("Triage notes").fill("Unable to reach mother");
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_the_patient_should_still_be_in_triage() {
  await expect(
    p.getByRole("row", {
      name: "Caridad Sipes Health questions need triage Triage started",
    }),
  ).toBeVisible();
}

async function and_i_enter_a_note_and_select_ready_to_vaccinate() {
  await p.getByLabel("Triage notes").fill("Reached mother, able to proceed");
  await p.getByRole("radio", { name: "Ready to vaccinate" }).click();
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function when_i_click_on_the_triage_complete_tab() {
  await p.getByRole("tab", { name: "Triage complete" }).click();
}
const and_i_click_on_the_triage_complete_tab =
  when_i_click_on_the_triage_complete_tab;

async function then_the_patient_should_be_in_ready_to_vaccinate() {
  await expect(
    p.getByRole("row", {
      name: "Caridad Sipes Health questions need triage Vaccinate",
    }),
  ).toBeVisible();
}

async function then_i_should_see_the_triage_details() {
  await expect(
    p.getByRole("radio", { name: "Ready to vaccinate" }),
  ).toBeChecked();
}

async function given_i_click_on_back() {
  await p.click("text=Back");
}

async function when_i_click_on_the_needs_triage_tab() {
  await p.getByRole("tab", { name: "Needs triage" }).click();
}

async function when_i_click_on_the_other_patient() {
  await p.getByRole("link", { name: "Blaine DuBuque" }).click();
}
const and_i_click_on_another_patient = when_i_click_on_the_other_patient;

async function and_i_enter_a_note_and_select_do_not_vaccinate() {
  await p
    .getByLabel("Triage notes")
    .fill("Father adament he does not want to vaccine");
  await p.getByRole("radio", { name: "Do not vaccinate" }).click();
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_i_should_be_back_on_the_needs_triage_tab() {
  await expect(p.getByRole("tab", { name: "Needs triage" })).toBeVisible();
}

async function and_i_should_not_see_the_other_patient() {
  await expect(
    p.getByRole("link", { name: "Blaine DuBuque" }),
  ).not.toBeVisible();
}

async function then_i_should_see_the_other_patient() {
  await expect(p.getByRole("link", { name: "Blaine DuBuque" })).toBeVisible();
}

async function then_i_should_see_their_do_not_vaccinate_status() {
  await expect(p.getByRole("textbox", { name: "Triage notes" })).toHaveValue(
    "Father adament he does not want to vaccine",
  );
  await expect(
    p.getByRole("radio", { name: "Do not vaccinate" }),
  ).toBeChecked();
}
