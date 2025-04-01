FROM public.ecr.aws/lambda/nodejs:20

# Copy package files
COPY package.json ${LAMBDA_TASK_ROOT}/

# Install dependencies
RUN cd ${LAMBDA_TASK_ROOT} && npm install

# Copy source code
COPY . ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler
CMD [ "src/index.handler" ] 