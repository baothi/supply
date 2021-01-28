namespace :docker do
  desc 'Push docker images to DockerHub'
  task :push_image do
    TAG = `git rev-parse --short HEAD`.strip

    puts 'Building Docker image'
    sh "docker build -t hingeto/supply-web:#{TAG} ."

    IMAGE_ID = `docker images | grep hingeto\/supply-web | head -n1 | awk '{print $3}'`.strip

    puts 'Tagging latest image'
    sh "docker tag #{IMAGE_ID} hingeto/supply-web:latest"

    puts 'Pushing Docker image'
    sh "docker push hingeto/supply-web:#{TAG}"
    sh 'docker push hingeto/supply-web:latest'

    puts 'Done'
  end
end
