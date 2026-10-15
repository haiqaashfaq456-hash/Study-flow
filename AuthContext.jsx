import { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(undefined); // undefined = loading
  const [profile, setProfile] = useState(null);

  useEffect(() => {
    let mounted = true;
    let authEventHandled = false;
    let currentUserId = null;

    async function loadProfile(userId) {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (mounted && currentUserId === userId) {
        setProfile(error ? null : data);
      }
    }

    function applySession(nextSession) {
      currentUserId = nextSession?.user?.id ?? null;
      setSession(nextSession);
      setProfile(null);

      if (currentUserId) {
        const userId = currentUserId;
        window.setTimeout(() => {
          if (mounted && currentUserId === userId) void loadProfile(userId);
        }, 0);
      }
    }

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      authEventHandled = true;
      applySession(nextSession);
    });

    supabase.auth.getSession()
      .then(({ data, error }) => {
        if (mounted && !authEventHandled) applySession(error ? null : data.session);
      })
      .catch(() => {
        if (mounted && !authEventHandled) applySession(null);
      });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  async function signUp(email, password, fullName) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName } },
    });
    return { data, error };
  }

  async function signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    return { data, error };
  }

  async function signInWithGoogle() {
    return supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: `${window.location.origin}/dashboard` },
    });
  }

  async function signOut() {
    return supabase.auth.signOut();
  }

  async function updateProfile(updates) {
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', session.user.id)
      .select()
      .single();
    if (!error) setProfile(data);
    return { data, error };
  }

  return (
    <AuthContext.Provider value={{ session, profile, signUp, signIn, signInWithGoogle, signOut, updateProfile, loading: session === undefined }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
