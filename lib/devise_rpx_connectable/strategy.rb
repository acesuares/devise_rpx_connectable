# encoding: utf-8

module Devise #:nodoc:
  module RpxConnectable #:nodoc:
    module Strategies #:nodoc:

      # Default strategy for signing in a user using RPX.
      # Redirects to sign_in page if it's not authenticated
      #
      class RpxConnectable < ::Devise::Strategies::Base

        def valid?
          valid_controller? && valid_params? && mapping.to.respond_to?('authenticate_with_rpx')
        end

        # Authenticate user with RPX.
        #
        def authenticate!
          klass = mapping.to
          raise StandardError, "RPXNow API key is not defined, please see the documentation of RPXNow gem to setup it." unless RPXNow.api_key.present?
          begin
            request_keys = klass.request_keys.inject({}) do |res, k|
              res[k] = params[k]
              res
            end rescue {}

            rpx_user = (RPXNow.user_data(params[:token], :extended => klass.rpx_extended_user_data, :additional => klass.rpx_additional_user_data) rescue nil)
            fail!(:rpx_invalid) and return unless rpx_user

            if user = klass.authenticate_with_rpx(:identifier => rpx_user["identifier"], :request_keys => request_keys )
              user.on_before_rpx_success(rpx_user)
              success!(user)
              return
            end
            
            fail!(:rpx_invalid) and return unless klass.rpx_auto_create_or_merge_account?

            # we need to create a new account or merge with an existing account.

            redirect_to 'http://www.suares.com'
            
#            user = klass.new
#            user.store_rpx_credentials!(rpx_user.merge(:request_keys => request_keys))
#            user.on_before_rpx_auto_create(rpx_user)
#
#            user.save(:validate => false)
#            user.on_before_rpx_success(rpx_user)
#            success!(user)
            
          rescue
            fail!(:rpx_invalid)
          end
        end
        
        protected
          def valid_controller?
            params[:controller].to_s =~ /sessions/
          end

          def valid_params?
            params[:token].present?
          end

      end
    end
  end
end

