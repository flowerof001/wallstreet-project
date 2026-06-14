import React, { useState } from 'react';
import { Card, Form, Input, Button, message } from 'antd';

interface Props {
  onLogin: (token: string) => void;
}

const AdminLogin: React.FC<Props> = ({ onLogin }) => {
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (values: { username: string; password: string }) => {
    setLoading(true);
    try {
      const res = await fetch('/api/v1/auth/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(values),
      });
      const data = await res.json();
      if (data.access_token) {
        localStorage.setItem('admin_token', data.access_token);
        onLogin(data.access_token);
        message.success('Login successful');
      } else {
        message.error('Login failed');
      }
    } catch {
      message.error('Network error');
    }
    setLoading(false);
  };

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #0A1E36 0%, #182738 100%)',
    }}>
      <Card
        title={<span style={{ color: '#BADBFF', fontSize: 24 }}>Wallstreet Admin</span>}
        style={{ width: 400, background: '#0F2B4A', borderColor: '#1A4060' }}
        styles={{ header: { background: '#0A2440', borderColor: '#1A4060' } }}
      >
        <Form onFinish={handleSubmit} layout="vertical">
          <Form.Item
            label={<span style={{ color: '#8899AA' }}>Username</span>}
            name="username"
            rules={[{ required: true, message: 'Please input your username' }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            label={<span style={{ color: '#8899AA' }}>Password</span>}
            name="password"
            rules={[{ required: true, message: 'Please input your password' }]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item>
            <Button
              type="primary"
              htmlType="submit"
              loading={loading}
              block
              style={{ background: '#003EA5' }}
            >
              Login
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
};

export default AdminLogin;
