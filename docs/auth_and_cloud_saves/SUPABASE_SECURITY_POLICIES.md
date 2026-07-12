# Supabase security policies

The table used for cloud save snapshots should enforce row-level access and only allow writes for the authenticated user.
Use the authenticated user id in the policy and avoid service role usage from the client app.
