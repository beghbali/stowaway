class ReceiptParser < Mail::Message

  RECEIPT_SENDERS = {
    'uber' => UberParser.from
  }

  def self.supported_senders
    RECEIPT_SENDERS.values.flatten
  end
end

