#!/usr/bin/env python3
"""
Simple tests for the Flask application
"""
import pytest
from app import app

@pytest.fixture
def client():
    """Create a test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_endpoint(client):
    """Test the index endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'message' in data
    assert 'status' in data
    assert data['status'] == 'healthy'

def test_health_endpoint(client):
    """Test the health endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'
    assert 'timestamp' in data

def test_hello_endpoint(client):
    """Test the hello API endpoint"""
    response = client.get('/api/hello?name=Test')
    assert response.status_code == 200
    data = response.get_json()
    assert 'message' in data
    assert 'Test' in data['message']

def test_metrics_endpoint(client):
    """Test the metrics endpoint"""
    response = client.get('/metrics')
    assert response.status_code == 200
    assert 'http_requests_total' in response.get_data(as_text=True)

