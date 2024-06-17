class OptimiseImageJob < ApplicationJob
  after_perform do |job|
    job.arguments.first.create_thumbnails!
  end
  def perform(record)
    if record.image_data.present?
      image_optim = ImageOptim.new(
        pngout: false,
        jpegoptim: { allow_lossy: true, max_quality: 85 }
      )

      record.image_attacher.file.open do |io|
        optimized_path = image_optim.optimize_image(io)

        if optimized_path.present?
          record.image_attacher.add_derivative(optimised: File.open(optimized_path.to_s))
          record.image_attacher.atomic_persist
        else
          record.image_attacher.create_derivatives(optimised: io)
        end
      end
    end
  end
end
