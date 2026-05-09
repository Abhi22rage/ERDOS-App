# Path Sammanay Integration & Execution Workflow

## Goal
Implement the contractor allotment, Path Sammanay excavation approval process, and automated SMS notifications for breakdown repair execution.

## Tasks
- [x] Task 1: **Database Schema Updates** - Add `excavation_required` (BOOLEAN DEFAULT FALSE) and `path_sammanay_cert_url` (VARCHAR) to the `work_orders` table. → Verify: Database reflects the new columns.
- [x] Task 2: **Contractor Allotment UI** - Create `AllotWorkModal` in the Flutter app for EE to select a contractor from the `contractor` table and submit. → Verify: EE can select a contractor and submit the form successfully.
- [x] Task 3: **Allotment API Logic** - Update `api_service.task.dart` to insert into `work_orders` and `approval_flow` (action: ASSIGNED), and update `breakdowns` status_id. → Verify: DB shows new `work_orders` row and status change.
- [ ] Task 4: (SKIPPED) **SMS Edge Function (Allotment)** - Create a Supabase Edge Function `send-sms` triggered on `work_orders` insert to send SMS to Contractor and Field Officials, logging to `notification_logs`. → Verify: Mock/test SMS is logged in `notification_logs` and HTTP 200 returned.
- [x] Task 5: **Excavation Requirement UI** - Add an "Excavation Required?" toggle on the Contractor's Work Details screen. If toggled ON, display the "Path Sammanay Portal" external link and the Certificate Upload UI. → Verify: Contractor can toggle requirement; upload UI only appears when required.
- [x] Task 6: **Certificate Upload UI & API** - Implement a file picker for the Path Sammanay certificate, uploading to Supabase storage and updating `work_orders.path_sammanay_cert_url`. → Verify: PDF/Image uploads successfully and URL saves to DB.
- [x] Task 7: **Work Commencement Action** - Add "Start Work" button. **Logic:** If `excavation_required` is true, block "Start Work" until `path_sammanay_cert_url` is provided. If false, allow immediately. Upon success, update `work_orders` status to `in_progress` and insert the initial stage into `execution_stages`. → Verify: Clicking "Start Work" enforces the certificate requirement and updates DB tables.
- [ ] Task 8: **SMS Edge Function (Commencement)** - Extend `send-sms` function to trigger on `work_orders` status change to `in_progress`, sending SMS to EE, SE, CE, and Secretary. → Verify: Edge function logs success and inserts into `notification_logs`.

## Done When
- [ ] EE can successfully allot work to a contractor.
- [ ] Contractor and field officials receive SMS notification of allotment.
- [ ] Contractor can specify excavation needs and upload the Path Sammanay certificate.
- [ ] Contractor can start work, triggering SMS to higher officials.
