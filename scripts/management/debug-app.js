// Quick debug script to identify frontend issues
console.log('Starting frontend debug...');

// Check if root element exists
const root = document.getElementById('root');
console.log('Root element found:', !!root);

// Check for any immediate JavaScript errors
window.addEventListener('error', (event) => {
  console.error('JavaScript Error:', event.error);
  console.error('Error message:', event.message);
  console.error('Error filename:', event.filename);
  console.error('Error line:', event.lineno);
});

// Check for unhandled promise rejections
window.addEventListener('unhandledrejection', (event) => {
  console.error('Unhandled Promise Rejection:', event.reason);
});

console.log('Debug script loaded successfully');