# Use the official Nginx image
FROM nginx:latest

# Copy index.html to the default Nginx HTML directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 to allow traffic
EXPOSE 80

# Run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
