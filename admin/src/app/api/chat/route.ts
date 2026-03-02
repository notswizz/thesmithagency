import { NextRequest, NextResponse } from 'next/server';
import OpenAI from 'openai';

export async function POST(req: NextRequest) {
  try {
    const { messages } = await req.json();
    const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: `You are an AI assistant for The Smith Agency, a fashion trade show staffing company.
You help the admin manage staff, bookings, shows, and clients.
Answer questions about staffing, scheduling, and general operations.
Be concise and helpful.`,
        },
        ...messages,
      ],
      max_tokens: 1000,
    });

    return NextResponse.json({
      message: completion.choices[0]?.message?.content || 'No response',
    });
  } catch (error) {
    console.error('Chat API error:', error);
    return NextResponse.json({ message: 'Failed to process request' }, { status: 500 });
  }
}
