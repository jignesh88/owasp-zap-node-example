'use client'

import { useEffect, useState } from 'react'

export default function Home() {
  const [backendStatus, setBackendStatus] = useState<string>('Loading...')

  useEffect(() => {
    fetch('/api/health')
      .then(res => res.json())
      .then(data => setBackendStatus(`Connected - ${data.service}`))
      .catch(() => setBackendStatus('Backend connection failed'))
  }, [])

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-md p-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">
          OWASP ZAP Security Testing Showcase
        </h1>
        <p className="text-gray-600 mb-4">
          This application demonstrates OWASP ZAP integration in CI/CD pipelines.
          It includes various endpoints and features that can be tested for security vulnerabilities.
        </p>
        <div className="bg-gray-100 p-4 rounded">
          <p className="text-sm">
            <strong>Backend Status:</strong> <span className="text-green-600">{backendStatus}</span>
          </p>
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-3">Features</h2>
          <ul className="space-y-2 text-gray-600">
            <li>• User Management API</li>
            <li>• Product Catalog API</li>
            <li>• Search Functionality</li>
            <li>• CRUD Operations</li>
            <li>• RESTful Endpoints</li>
          </ul>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-3">Security Testing</h2>
          <ul className="space-y-2 text-gray-600">
            <li>• Baseline scan on feature branches</li>
            <li>• Full scan on master/release</li>
            <li>• Automated CI/CD integration</li>
            <li>• Vulnerability reporting</li>
            <li>• GitHub PR comments</li>
          </ul>
        </div>
      </div>
    </div>
  )
}