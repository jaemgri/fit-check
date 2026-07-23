require "net/http"
require "uri"
require "securerandom"

class OpenaiTryonService
  class Error < StandardError; end

  ENDPOINT = "https://api.openai.com/v1/images/edits"
  MODEL = "gpt-image-1"

  PROMPT = <<~PROMPT.strip
    You are given several images: the first is a photo of a person, the
    rest are photos of clothing items. Generate a single new
    photorealistic image of the exact same person from the first photo
    wearing all of the clothing items shown in the other photos,
    combined into one cohesive outfit.

    Preserve the person's exact facial identity, facial features,
    skin tone, hair, body shape and proportions, pose, and the
    background from the first photo as precisely as possible -- do
    not change who the person is or how they look. Preserve the exact
    color, pattern, text, logos, and design details of each clothing
    item as precisely as possible -- do not invent or alter design
    details. Only change the clothing being worn; everything else
    should stay as close to the original photos as possible.
  PROMPT

  def initialize(person_photo:, clothing_photos:, variations: 1)
    @person_photo = person_photo
    @clothing_photos = clothing_photos
    @variations = variations
  end

  def call
    api_key = ENV["OPENAI_API_KEY"]
    raise Error, "OPENAI_API_KEY is not set" if api_key.blank?

    threads = @variations.times.map do
      Thread.new { perform_single_request(api_key) }
    end

    results = threads.map(&:value)
    successes = results.select { |r| r.is_a?(Hash) }

    if successes.empty?
      first_error = results.find { |r| r.is_a?(StandardError) }
      raise(first_error || Error.new("OpenAI did not return any images"))
    end

    successes
  end

  private

  def perform_single_request(api_key)
    uri = URI(ENDPOINT)
    boundary = SecureRandom.hex(16)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 180

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = build_multipart_body(boundary)

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      return Error.new("OpenAI API error (#{response.code}): #{response.body}")
    end

    parsed = JSON.parse(response.body)
    data = parsed["data"]&.first

    return Error.new(parsed.dig("error", "message").presence || "OpenAI did not return an image") unless data

    { bytes: Base64.decode64(data["b64_json"]), content_type: "image/png" }
  rescue => e
    Error.new(e.message)
  end

  def build_multipart_body(boundary)
    body = "".b
    body << text_field(boundary, "model", MODEL)
    body << text_field(boundary, "prompt", PROMPT)
    body << text_field(boundary, "n", "1")
    body << text_field(boundary, "input_fidelity", "high")
    body << text_field(boundary, "quality", "high")
    body << text_field(boundary, "size", "1024x1536")

    body << file_field(boundary, "image[]", @person_photo, "person.jpg")
    @clothing_photos.each_with_index do |photo, i|
      body << file_field(boundary, "image[]", photo, "clothing_#{i + 1}.jpg")
    end

    body << "--#{boundary}--\r\n".b
    body
  end

  def text_field(boundary, name, value)
    (
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" \
      "#{value}\r\n"
    ).b
  end

  def file_field(boundary, name, attachment, filename)
    header = (
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"\r\n" \
      "Content-Type: #{attachment.content_type}\r\n\r\n"
    ).b
    header + attachment.download.b + "\r\n".b
  end
end
