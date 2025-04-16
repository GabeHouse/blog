# Build stage
FROM node:18 AS build
WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json* ./
RUN npm ci

# Copy source files and build the app
COPY . .
RUN npm run build

# Lambda runtime stage
FROM public.ecr.aws/lambda/nodejs:18

# Copy built assets from the build stage
COPY --from=build /app/dist /var/task/dist

# Install express and serverless-http for serving the static files
WORKDIR /var/task
COPY --from=build /app/package.json /app/package-lock.json* ./
RUN npm install express serverless-http

# Add the Lambda handler code
COPY lambda-handler.js ./

# Set the CMD to your handler
CMD [ "lambda-handler.handler" ]