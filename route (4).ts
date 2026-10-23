import {NextRequest,NextResponse} from 'next/server';import {serverDb} from '@/lib/supabase';
export async function GET(req:NextRequest){const code=new URL(req.url).searchParams.get('code');if(code){await (await serverDb()).auth.exchangeCodeForSession(code)}return NextResponse.redirect(new URL('/',req.url))}
