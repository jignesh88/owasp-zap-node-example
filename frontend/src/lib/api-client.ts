// API Client for communicating with separated backend

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

console.log('API Client initialized with backend URL:', BACKEND_URL);

export const apiClient = {
  get: async (endpoint: string) => {
    const url = `${BACKEND_URL}${endpoint}`;
    console.log('API GET:', url);
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return response.json();
  },
  
  post: async (endpoint: string, data: any) => {
    const url = `${BACKEND_URL}${endpoint}`;
    console.log('API POST:', url, data);
    
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return response.json();
  },
  
  put: async (endpoint: string, data: any) => {
    const url = `${BACKEND_URL}${endpoint}`;
    console.log('API PUT:', url, data);
    
    const response = await fetch(url, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return response.json();
  },
  
  delete: async (endpoint: string) => {
    const url = `${BACKEND_URL}${endpoint}`;
    console.log('API DELETE:', url);
    
    const response = await fetch(url, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return response.json();
  }
};

export default apiClient;