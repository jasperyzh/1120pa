import type { APIRoute } from "astro";
import { createClient } from "@supabase/supabase-js";

const RESEND_API_KEY = import.meta.env.RESEND_API_KEY;
const TURNSTILE_SECRET = import.meta.env.TURNSTILE_SECRET_KEY;
const SUPABASE_URL = import.meta.env.PUBLIC_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = import.meta.env.SUPABASE_SERVICE_ROLE_KEY;

interface FormData {
  _client_id?: string;
  _form_id?: string;
  _redirect?: string;
  _website?: string;
  _turnstile_token?: string;
  [key: string]: string | undefined;
}

interface SubmissionResult {
  success: boolean;
  message: string;
  redirectUrl?: string;
}

async function verifyTurnstile(token: string): Promise<boolean> {
  if (!TURNSTILE_SECRET || TURNSTILE_SECRET === "placeholder") {
    console.warn("Turnstile secret not configured, skipping verification");
    return true;
  }

  try {
    const response = await fetch(
      "https://challenges.cloudflare.com/turnstile/v0/siteverify",
      {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: `secret=${TURNSTILE_SECRET}&response=${token}`,
      }
    );
    const data = await response.json();
    return data.success === true;
  } catch {
    console.error("Turnstile verification failed");
    return false;
  }
}

async function sendEmail(payload: Record<string, string>, formId: string) {
  if (!RESEND_API_KEY) {
    console.warn("Resend API key not configured, skipping email");
    return;
  }

  const submissionTime = new Date().toLocaleString("en-MY", {
    timeZone: "Asia/Kuala_Lumpur",
    dateStyle: "full",
    timeStyle: "short",
  });

  const emailHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f5f5f5;">
      <div style="background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <h2 style="color: #333; margin-top: 0; border-bottom: 2px solid #4F46E5; padding-bottom: 10px;">
          📬 New Form Submission
        </h2>
        
        <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
          <tr style="background: #f8f9fa;">
            <td style="padding: 12px; border: 1px solid #dee2e6; font-weight: 600; width: 120px;">Form Type</td>
            <td style="padding: 12px; border: 1px solid #dee2e6; text-transform: capitalize;">${formId}</td>
          </tr>
          ${Object.entries(payload)
            .filter(([key]) => !key.startsWith("_"))
            .map(([key, value]) => `
          <tr>
            <td style="padding: 12px; border: 1px solid #dee2e6; font-weight: 600; text-transform: capitalize;">${key}</td>
            <td style="padding: 12px; border: 1px solid #dee2e6;">${value || "-"}</td>
          </tr>
          `).join("")}
        </table>
        
        <div style="background: #f8f9fa; padding: 15px; border-radius: 4px; margin-top: 20px;">
          <p style="margin: 0; color: #666; font-size: 12px;">
            <strong>Submitted:</strong> ${submissionTime}<br>
            <strong>Source:</strong> ${payload._redirect || "Direct form"}
          </p>
        </div>
      </div>
    </body>
    </html>
  `;

  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "1120pa Contact <onboarding@resend.dev>",
        to: ["jasper.yzh@gmail.com"],
        subject: `[1120pa] New ${formId} Submission`,
        html: emailHtml,
      }),
    });

    const data = await response.json();
    
    if (!response.ok) {
      console.error("Resend API error:", data);
    }
  } catch (error) {
    console.error("Failed to send email:", error);
  }
}

export const POST: APIRoute = async ({ request, clientAddress }) => {
  const result: SubmissionResult = {
    success: false,
    message: "",
    redirectUrl: "/thank-you",
  };

  try {
    const contentType = request.headers.get("content-type") || "";

    let formData: FormData = {};

    if (contentType.includes("application/x-www-form-urlencoded")) {
      const formText = await request.text();
      const params = new URLSearchParams(formText);
      params.forEach((value, key) => {
        formData[key] = value;
      });
    } else {
      formData = await request.json();
    }

    const honeypot = formData._website?.trim();
    if (honeypot) {
      console.log("Honeypot triggered - likely bot submission");
      result.message = "Submission rejected";
      result.redirectUrl = "/";
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const turnstileToken = formData._turnstile_token;
    if (turnstileToken && TURNSTILE_SECRET) {
      const isValid = await verifyTurnstile(turnstileToken);
      if (!isValid) {
        result.message = "Security verification failed. Please try again.";
        return new Response(JSON.stringify(result), {
          status: 403,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    const clientId = formData._client_id || "default";
    const formId = formData._form_id || "contact";
    const redirectUrl =
      formData._redirect || (formId === "contact" ? "/thank-you" : "/");

    const payload: Record<string, string> = {};
    Object.entries(formData).forEach(([key, value]) => {
      if (!key.startsWith("_") && value) {
        payload[key] = value;
      }
    });

    console.log(`Form submission: ${formId} from ${clientAddress}`);

    if (SUPABASE_URL && SUPABASE_SERVICE_KEY) {
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

      const { error: dbError } = await supabase
        .from("form_submissions")
        .insert({
          client_id: clientId === "default" ? null : clientId,
          form_id: formId,
          payload: payload,
          ip_address: clientAddress,
          user_agent: request.headers.get("user-agent"),
        });

      if (dbError) {
        console.error("Database error:", dbError);
        result.message = "Failed to save submission. Please try again.";
        return new Response(JSON.stringify(result), {
          status: 500,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    await sendEmail(payload, formId);

    result.success = true;
    result.message = "Form submitted successfully";
    result.redirectUrl = redirectUrl;

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        Location: redirectUrl,
      },
    });
  } catch (error) {
    console.error("Form submission error:", error);
    result.message = "An error occurred. Please try again.";

    return new Response(JSON.stringify(result), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
};

export const GET: APIRoute = async () => {
  return new Response(
    JSON.stringify({ error: "Method not allowed" }),
    {
      status: 405,
      headers: { "Content-Type": "application/json" },
    }
  );
};
