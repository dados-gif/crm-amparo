import { serverDb } from './supabase';
export async function authenticated(){const db=await serverDb(); const {data:{user}}=await db.auth.getUser(); if(!user)return null; const {data:profile}=await db.from('profiles').select('id,role,active,full_name').eq('id',user.id).single();if(!profile?.active)return null;return {db,user,profile};}
export async function adminOnly(){const a=await authenticated();return a?.profile.role==='admin'?a:null}
