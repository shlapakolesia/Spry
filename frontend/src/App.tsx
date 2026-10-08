import { useCallback, useEffect, useState } from "react";
import { LogIn, LogOut, Plus } from "lucide-react";
import { useAuth } from "react-oidc-context";

import { listMeetings } from "@/api/meetings";
import { MeetingList } from "@/components/MeetingList";
import { NewMeetingDialog } from "@/components/NewMeetingDialog";
import { Button } from "@/components/ui/button";
import type { Meeting } from "@/types/meeting";

const COGNITO_DOMAIN =
  "https://spry-auth-lab3-2026.auth.eu-north-1.amazoncognito.com";

const CLIENT_ID = "1uucla7u51q5an1th1j48hjtbi";

export default function App() {
  const auth = useAuth();

  const [meetings, setMeetings] = useState<Meeting[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);

  const load = useCallback(async () => {
    try {
      setMeetings(await listMeetings());
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load meetings");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  // The submission URL /login/ automatically redirects to Cognito.
  useEffect(() => {
    if (
      window.location.pathname === "/login/" &&
      !auth.isLoading &&
      !auth.isAuthenticated &&
      !auth.activeNavigator
    ) {
      void auth.signinRedirect();
    }
  }, [
    auth.isLoading,
    auth.isAuthenticated,
    auth.activeNavigator,
    auth.signinRedirect,
  ]);

  const handleSignOut = async () => {
    await auth.removeUser();

    const logoutUri = `${window.location.origin}/`;

    window.location.href =
      `${COGNITO_DOMAIN}/logout` +
      `?client_id=${CLIENT_ID}` +
      `&logout_uri=${encodeURIComponent(logoutUri)}`;
  };

  if (auth.isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-neutral-50">
        <p>Loading...</p>
      </div>
    );
  }

  if (auth.error) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-neutral-50">
        <p>Authentication error: {auth.error.message}</p>
      </div>
    );
  }

  if (
    window.location.pathname === "/login/" &&
    !auth.isAuthenticated
  ) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-neutral-50">
        <p>Redirecting to sign in...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      <main className="mx-auto max-w-2xl px-6 py-14">
        <header className="mb-8 flex items-start justify-between gap-4">
          <div>
            <h1 className="text-3xl font-semibold tracking-tight">Meetings</h1>

            {!loading && !error && (
              <p className="mt-1 text-sm text-muted-foreground">
                {meetings.length === 1
                  ? "1 meeting"
                  : `${meetings.length} meetings`}
              </p>
            )}

            {auth.isAuthenticated && (
              <p className="mt-2 text-sm text-muted-foreground">
                Signed in as {auth.user?.profile.email}
              </p>
            )}
          </div>

          <div className="flex items-center gap-2">
            {auth.isAuthenticated ? (
              <Button variant="outline" onClick={() => void handleSignOut()}>
                <LogOut className="size-4" />
                Sign out
              </Button>
            ) : (
              <Button
                variant="outline"
                onClick={() => {
                  window.location.href = "/login/";
                }}
              >
                <LogIn className="size-4" />
                Sign in
              </Button>
            )}

            <Button onClick={() => setDialogOpen(true)}>
              <Plus className="size-4" />
              New meeting
            </Button>
          </div>
        </header>

        <MeetingList
          meetings={meetings}
          loading={loading}
          error={error}
          onNew={() => setDialogOpen(true)}
        />
      </main>

      <NewMeetingDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        onCreated={load}
      />
    </div>
  );
}
