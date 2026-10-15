import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './src/contexts/AuthContext';
import Layout from './src/components/Layout/Layout';
import AuthPage from './src/pages/AuthPage';
import Dashboard from './src/pages/Dashboard';
import Tasks from './src/pages/Tasks';
import StudyPlanner from './src/pages/StudyPlanner';
import Analytics from './src/pages/Analytics';
import Settings from './src/pages/Settings';
import LoadingScreen from './src/components/ui/LoadingScreen';

function ProtectedRoute({ children }) {
  const { session, loading } = useAuth();
  if (loading) return <LoadingScreen />;
  if (!session) return <Navigate to="/auth" replace />;
  return children;
}

function PublicRoute({ children }) {
  const { session, loading } = useAuth();
  if (loading) return <LoadingScreen />;
  if (session) return <Navigate to="/dashboard" replace />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/auth" element={<PublicRoute><AuthPage /></PublicRoute>} />
      <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard"    element={<Dashboard />} />
        <Route path="tasks"        element={<Tasks />} />
        <Route path="planner"      element={<StudyPlanner />} />
        <Route path="analytics"    element={<Analytics />} />
        <Route path="settings"     element={<Settings />} />
      </Route>
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}
