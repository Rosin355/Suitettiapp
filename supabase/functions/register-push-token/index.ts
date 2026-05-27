import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { deviceToken, platform, environment, bundleId, appVersion, buildNumber } = body

  // Validation
  if (!deviceToken || typeof deviceToken !== 'string' || deviceToken.trim() === '') {
    return new Response(JSON.stringify({ error: 'deviceToken is required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  if (platform !== 'ios') {
    return new Response(JSON.stringify({ error: 'platform must be ios' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  if (environment !== 'sandbox' && environment !== 'production') {
    return new Response(JSON.stringify({ error: 'environment must be sandbox or production' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  if (!bundleId || typeof bundleId !== 'string' || bundleId.trim() === '') {
    return new Response(JSON.stringify({ error: 'bundleId is required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  const now = new Date().toISOString()

  const { error } = await supabase
    .from('push_device_tokens')
    .upsert(
      {
        device_token: (deviceToken as string).trim(),
        platform,
        environment,
        bundle_id: (bundleId as string).trim(),
        app_version: typeof appVersion === 'string' ? appVersion : null,
        build_number: typeof buildNumber === 'string' ? buildNumber : null,
        is_enabled: true,
        last_seen_at: now,
        updated_at: now,
      },
      { onConflict: 'device_token' },
    )

  if (error) {
    console.error('[register-push-token] upsert error:', error.message)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
