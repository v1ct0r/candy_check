module CandyCheck
  module AppStore
    # Store multiple {Receipt}s in order to perform collective operation on them
    class ReceiptCollection

      PENDING_RENEWAL_INFO_KEYS = %w(expiration_intent
                                     is_in_billing_retry_period
                                     auto_renew_status
                                     auto_renew_product_id).freeze

      # Multiple receipts as in verfication response
      # @return [Array<Receipt>]
      attr_reader :receipts
      attr_reader :pending_renewal_info

      # Initializes a new instance which bases on a JSON result
      # from Apple's verification server
      # @param attributes [Array<Hash>] raw data from Apple's server
      def initialize(attributes, pending_renewal_info)
        @receipts = attributes.map {|r| Receipt.new(r) }.sort{ |a, b|
          a.purchase_date - b.purchase_date
        }
        @pending_renewal_info = pending_renewal_info
      end

      # Check if the latest expiration date is passed
      # @return [bool]
      def expired?
        expires_at.to_time <= Time.now.utc
      end

      # Check if in trial
      # @return [bool]
      def trial?
        @receipts.last.is_trial_period
      end

      # Get latest expiration date
      # @return [DateTime]
      def expires_at
        @receipts.last.expires_date
      end

      # Get number of overdue days. If this is negative, it is not overdue.
      # @return [Integer]
      def overdue_days
        (Date.today - expires_at.to_date).to_i
      end

      def cancelled?
        it last_info = @pending_renewal_info&.last
          return last_info.key?('auto_renew_status') && last_info['auto_renew_status'] == '0'
        end
        return false
      end
    end
  end
end
