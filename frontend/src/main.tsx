import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { AuthProvider } from "react-oidc-context";
import App from "@/App";
import "@/index.css";

const cognitoAuthConfig = {
  authority:
    "https://cognito-idp.eu-north-1.amazonaws.com/eu-north-1_m4dJRmho3",

  client_id: "1uucla7u51q5an1th1j48hjtbi",

  redirect_uri:
    "https://d3b5dueyhkda58.cloudfront.net/auth/callback/",

  response_type: "code",

  scope: "openid email profile",

  onSigninCallback: () => {
    window.history.replaceState({}, document.title, "/");
  },
};

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <AuthProvider {...cognitoAuthConfig}>
      <App />
    </AuthProvider>
  </StrictMode>,
);
