# Property management flow map

## Tables (`pm_*`)

`pm_properties`, `pm_buildings`, `pm_units`, `pm_tenants`, `pm_leases`, `pm_rent_invoices`, `pm_rent_payments`, `pm_maintenance_requests`, `pm_property_staff`, `pm_property_notices`, `pm_rent_reminder_log`, `pm_pricing_tiers`, `pm_rent_payment_claims`, `pm_payout_destinations`, `pm_platform_fee_ledger`, `pm_payout_batches`, `pm_complaints`

(Accessed via PM modules; may not all appear in generated Supabase types.)

## Web surfaces

Mirrored under `/landlord/manage/**`, `/agency/manage/**`, `/manager/manage/**`:

- list / new / subscribe  
- `$propertyId`: overview, units, tenants, rent, maintenance, complaints  

Tenant resident: `/tenant/rent`, `/tenant/maintenance`, `/tenant/complaints`, `/tenant/invite/$token`.

## Server modules

- `api/pm.functions.ts` — property/units/tenants/leases/invoices/staff/dashboard  
- `api/pm-module.functions.ts` — module status + subscribe  
- `api/pm-tenant-rent.functions.ts` — tenant invoices + payPmRent (IntaSend)  
- `api/pm-maintenance*.ts`, `pm-complaints.functions.ts`, `pm-payout.functions.ts`, `pm-admin.functions.ts`  
- `lib/pm/module-gate.ts`, permissions, intasend-*, rent-fulfillment  

## Flutter / BFF

Expose under `/api/mobile/v1/property-management/*` and `/api/mobile/v1/tenants/*` wrapping the above — no new PM business rules in Dart.

## Staff permissions

PM staff roles: `owner | property_manager | caretaker | security | accountant | maintenance_supervisor | reception` with permission strings in `lib/pm/permissions.ts`. BFF must enforce the same checks as web.
