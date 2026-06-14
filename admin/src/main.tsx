import React, { useState } from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ConfigProvider, theme } from 'antd';
import Dashboard from './pages/Dashboard';
import AdminLogin from './pages/Login';

const App: React.FC = () => {
  const [token, setToken] = useState(localStorage.getItem('admin_token'));

  if (!token) {
    return <AdminLogin onLogin={setToken} />;
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Dashboard />} />
      </Routes>
    </BrowserRouter>
  );
};

// 深蓝主题
const darkTheme = {
  algorithm: theme.darkAlgorithm,
  token: {
    colorPrimary: '#003EA5',
    colorBgBase: '#0A1E36',
    colorBgContainer: '#0F2B4A',
    colorBorder: '#1A4060',
    colorText: '#BADBFF',
    colorTextSecondary: '#8899AA',
  },
};

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ConfigProvider theme={darkTheme}>
      <App />
    </ConfigProvider>
  </React.StrictMode>,
);
