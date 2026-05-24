import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY

let supabase = null

if (supabaseUrl && supabaseKey) {
  supabase = createClient(supabaseUrl, supabaseKey)
}

export function getSupabase() {
  return supabase
}

export function isConfigured() {
  return !!supabase
}

export async function register(email, password, pseudo) {
  if (!supabase) throw new Error('Supabase non configuré')

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { pseudo } },
  })

  if (error) throw error
  return data
}

export async function login(email, password) {
  if (!supabase) throw new Error('Supabase non configuré')

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) throw error
  return data
}

export async function logout() {
  if (!supabase) return
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}

export async function getSession() {
  if (!supabase) return null
  const { data } = await supabase.auth.getSession()
  return data.session
}

export function onAuthChange(callback) {
  if (!supabase) {
    callback(null)
    return () => {}
  }

  const { data } = supabase.auth.onAuthStateChange((event, session) => {
    callback(session)
  })

  return data.subscription.unsubscribe
}

export async function getProfile(userId) {
  if (!supabase) return null

  const { data, error } = await supabase
    .from('profiles')
    .select('pseudo')
    .eq('id', userId)
    .maybeSingle()

  if (error || !data) return null
  return data
}

export async function resetPassword(email) {
  if (!supabase) throw new Error('Supabase non configuré')

  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: window.location.origin,
  })

  if (error) throw error
}
