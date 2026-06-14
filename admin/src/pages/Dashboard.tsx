import React, { useEffect, useState } from 'react';
import { Table, Card, Space, Button, Tag, Input, Modal, Form, Select, Switch, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';

interface UserRecord {
  user_id: string;
  phone: string;
  country_code: string;
  email?: string;
  country?: string;
  ip_address?: string;
  is_active: boolean;
  is_admin: boolean;
  watchlist: string[];
  created_at: string;
  last_login_at?: string;
}

const AdminDashboard: React.FC = () => {
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [selectedUser, setSelectedUser] = useState<UserRecord | null>(null);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [editForm] = Form.useForm();

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/v1/admin/users?page=${page}&size=20`, {
        headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` },
      });
      const data = await res.json();
      setUsers(data.users);
      setTotal(data.total);
    } catch (e) {
      message.error('Failed to fetch users');
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchUsers();
  }, [page]);

  const handleEdit = (user: UserRecord) => {
    setSelectedUser(user);
    editForm.setFieldsValue({
      phone: user.phone,
      email: user.email || '',
      country: user.country || '',
      is_active: user.is_active,
    });
    setEditModalOpen(true);
  };

  const handleEditSubmit = async () => {
    if (!selectedUser) return;
    setSubmitting(true);
    try {
      const values = editForm.getFieldsValue();
      const res = await fetch(`/api/v1/admin/users/${selectedUser.user_id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${localStorage.getItem('admin_token')}`,
        },
        body: JSON.stringify(values),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || 'Failed to update user');
      }

      message.success('User updated successfully');
      setEditModalOpen(false);
      fetchUsers();
    } catch (e: any) {
      message.error(e.message || 'Failed to update user');
    }
    setSubmitting(false);
  };

  const handleDelete = (user: UserRecord) => {
    setSelectedUser(user);
    setDeleteModalOpen(true);
  };

  const confirmDelete = async () => {
    if (!selectedUser) return;
    setSubmitting(true);
    try {
      const res = await fetch(`/api/v1/admin/users/${selectedUser.user_id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` },
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || 'Failed to delete user');
      }

      message.success('User deleted');
      setDeleteModalOpen(false);
      fetchUsers();
    } catch (e: any) {
      message.error(e.message || 'Failed to delete user');
    }
    setSubmitting(false);
  };

  const columns: ColumnsType<UserRecord> = [
    {
      title: 'User ID',
      dataIndex: 'user_id',
      key: 'user_id',
      width: 160,
      ellipsis: true,
      render: (id: string) => (
        <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
          {id.substring(0, 12)}...
        </span>
      ),
    },
    {
      title: 'Phone',
      key: 'phone',
      render: (_, r) => `${r.country_code || '+86'} ${r.phone}`,
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      render: (email?: string) => email || '-',
    },
    {
      title: 'Country',
      dataIndex: 'country',
      key: 'country',
      render: (c?: string) => c || '-',
    },
    {
      title: 'IP',
      dataIndex: 'ip_address',
      key: 'ip_address',
      render: (ip?: string) => ip || '-',
    },
    {
      title: 'Admin',
      dataIndex: 'is_admin',
      key: 'is_admin',
      render: (admin: boolean) => (
        <Tag color={admin ? 'blue' : 'default'}>{admin ? 'Yes' : 'No'}</Tag>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'is_active',
      key: 'is_active',
      render: (active: boolean) => (
        <Tag color={active ? 'green' : 'red'}>{active ? 'Active' : 'Deleted'}</Tag>
      ),
    },
    {
      title: 'Watchlist',
      dataIndex: 'watchlist',
      key: 'watchlist',
      render: (wl: string[]) => wl?.length || 0,
    },
    {
      title: 'Created',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (d: string) => d ? new Date(d).toLocaleDateString() : '-',
    },
    {
      title: 'Actions',
      key: 'actions',
      fixed: 'right',
      render: (_, record) => (
        <Space>
          <Button size="small" type="primary" ghost onClick={() => handleEdit(record)}>
            Edit
          </Button>
          <Button size="small" danger onClick={() => handleDelete(record)}>
            Delete
          </Button>
        </Space>
      ),
    },
  ];

  // Country options for the edit form
  const countryOptions = [
    { value: 'CN', label: 'China' },
    { value: 'TW', label: 'Taiwan' },
    { value: 'HK', label: 'Hong Kong' },
    { value: 'US', label: 'United States' },
    { value: 'JP', label: 'Japan' },
    { value: 'KR', label: 'Korea' },
    { value: 'IN', label: 'India' },
    { value: 'VN', label: 'Vietnam' },
    { value: 'PH', label: 'Philippines' },
    { value: 'MY', label: 'Malaysia' },
    { value: 'GB', label: 'United Kingdom' },
    { value: 'FR', label: 'France' },
    { value: 'DE', label: 'Germany' },
    { value: 'ES', label: 'Spain' },
    { value: 'IT', label: 'Italy' },
    { value: 'RU', label: 'Russia' },
    { value: 'AE', label: 'UAE' },
  ];

  return (
    <div style={{ padding: 24, background: '#0A1E36', minHeight: '100vh' }}>
      <h1 style={{ color: '#BADBFF', marginBottom: 24 }}>
        Wallstreet Admin Dashboard
      </h1>

      <Card
        title={
          <span style={{ color: '#5DA3F3' }}>
            User Management ({total} users)
          </span>
        }
        style={{ background: '#0F2B4A', borderColor: '#1A4060' }}
        styles={{
          header: { background: '#0A2440', color: '#BADBFF' },
          body: { background: '#0F2B4A' },
        }}
      >
        <Table
          columns={columns}
          dataSource={users}
          loading={loading}
          rowKey="user_id"
          scroll={{ x: 1200 }}
          pagination={{
            current: page,
            total,
            pageSize: 20,
            onChange: setPage,
            showSizeChanger: false,
            showTotal: (t) => `Total ${t} users`,
          }}
          style={{ background: 'transparent' }}
          locale={{ emptyText: 'No users found' }}
        />
      </Card>

      {/* Edit User Modal */}
      <Modal
        title="Edit User"
        open={editModalOpen}
        onCancel={() => setEditModalOpen(false)}
        onOk={handleEditSubmit}
        confirmLoading={submitting}
        okText="Save"
        cancelText="Cancel"
        destroyOnClose
      >
        <Form layout="vertical" form={editForm}>
          <Form.Item label="Phone" name="phone">
            <Input placeholder="Phone number" />
          </Form.Item>
          <Form.Item label="Email" name="email">
            <Input placeholder="Email address" type="email" />
          </Form.Item>
          <Form.Item label="Country" name="country">
            <Select
              placeholder="Select country"
              options={countryOptions}
              showSearch
              filterOption={(input, option) =>
                (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
              }
            />
          </Form.Item>
          <Form.Item label="Active" name="is_active" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>

      {/* Delete User Modal */}
      <Modal
        title="Delete User"
        open={deleteModalOpen}
        onOk={confirmDelete}
        onCancel={() => setDeleteModalOpen(false)}
        confirmLoading={submitting}
        okText="Delete"
        cancelText="Cancel"
        okButtonProps={{ danger: true }}
      >
        <p>Are you sure you want to delete the following user?</p>
        <p>
          <strong>User ID:</strong>{' '}
          <code style={{ fontSize: 12 }}>{selectedUser?.user_id}</code>
        </p>
        <p>
          <strong>Phone:</strong> {selectedUser?.country_code}{' '}
          {selectedUser?.phone}
        </p>
        <p style={{ color: '#FF5757' }}>
          Warning: This action cannot be undone.
        </p>
      </Modal>
    </div>
  );
};

export default AdminDashboard;
