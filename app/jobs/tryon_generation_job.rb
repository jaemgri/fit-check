class TryonGenerationJob < ApplicationJob
  queue_as :default

  def perform(tryon)
    results = OpenaiTryonService.new(
      person_photo: tryon.person_photo,
      clothing_photos: tryon.clothing_photos,
      variations: 2
    ).call

    results.each_with_index do |result, index|
      extension = result[:content_type].split("/").last
      tryon.result_images.attach(
        io: StringIO.new(result[:bytes]),
        filename: "result_#{index + 1}.#{extension}",
        content_type: result[:content_type]
      )
    end

    tryon.update!(status: "complete")
  rescue OpenaiTryonService::Error => e
    tryon.update!(status: "failed", error_message: e.message)
  end
end
