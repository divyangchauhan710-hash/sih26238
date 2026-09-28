import app from './app';

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 EkVidya API Gateway running on port ${PORT}`);
  console.log(`🔗 Health Check: http://localhost:${PORT}/health`);
});
