require_relative 'error/base'
require_relative 'connectable'

module JSONAPI
  module Model
    # Base class to inherit specific models based on working with remote JSONAPI endpoints
    class Base
      include ActiveModel::Model
      include Connectable

      # TODO: stop requirement that assumes remote API uses UUIDs for id
      # (but treat as an add on option?)
      VALID_UUID_REGEXP = /\h{8}-\h{4}-4\h{3}-[89AB]\h{3}-\h{12}/i.freeze # version 4, non-null

      attr_reader :id

      validates :id,
                presence: true,
                format: { with: VALID_UUID_REGEXP, message: 'invalid UUID format' },
                if: :persisted?

      class << self
        # Retrieve a resource by its ID from remote API
        #
        # @param [String] id ID of resource to retrieve
        # @raise [Error::NoEndpointDefined] when no endpoint configured
        # @raise [Error::InvalidIdArgument] if given ID is not a String
        # @raise [Error::NotFound] if resource not found by its ID on remote API
        # @raise [Error::UnavailableHost] when remote API cannot be connected to
        # @raise [Error::RequestFailed] for other request errors from remote API
        # @return [Object] resource
        def find(id = nil)
          raise Error::NoEndpointDefined unless respond_to?(:endpoint)
          raise Error::InvalidIdArgument unless id.is_a?(String) && id&.match?(VALID_UUID_REGEXP)

          new(parse(connection.get(path: "#{endpoint}/#{id}"))).tap do |obj|
            obj.__send__(:exists!)
          end
        rescue Error::RequestFailed => e
          on_find_request_failed(e, id)
        rescue Excon::Error::Socket => e
          on_socket_error(e)
        end
        alias_method :[], :find

        # Retrieve all resource from remote API
        #
        # @raise [Error::NoEndpointDefined] when no endpoint configured
        # @raise [Error::UnavailableHost] when remote API cannot be connected to
        # @return [Array] array of resources
        def all
          raise Error::NoEndpointDefined unless respond_to?(:endpoint)

          parse(connection.get(path: endpoint)).map do |attributes|
            new(attributes).tap { |obj| obj.__send__(:exists!) }
          end
        rescue Excon::Error::Socket => e
          on_socket_error(e)
        end

        # Create resource using remote API
        #
        # @param [Hash] attributes attributes for resource being created
        # @raise [Error::NoEndpointDefined] when no endpoint configured
        # @raise [Error::UnavailableHost] when remote API cannot be connected to
        # @raise [Error::NotCreated] when creation fails on remote API
        # @return [String] ID of created resource
        def create(attributes = {})
          raise Error::NoEndpointDefined unless respond_to?(:endpoint)

          object = new(attributes.except(:id))
          result = object.__send__(:create)
          result ? object.id : (raise Error::NotCreated)
        end

        # Create resource using remote API, immediately raising any errors encountered
        # when processing the request against the remote API
        #
        # @param [Hash] attributes attributes for resource being created
        # @raise [Error::NoEndpointDefined] when no endpoint configured
        # @raise [Error::ProhibitedCreation] when resource already exists or an ID assigned
        # @raise [Error::ValidationsFailed] when resource does not pass validations
        # @raise [Error::RequestFailed] for other request errors from remote API
        # @raise [Error::UnavailableHost] when remote API cannot be connected to
        # @raise [Error::NotCreated] when created object has no ID
        # @return [String] ID of created resource
        def create!(attributes = {})
          raise Error::NoEndpointDefined unless respond_to?(:endpoint)

          object = new(attributes.except(:id))
          result = object.__send__(:create!)
          result ? object.id : (raise Error::NotCreated)
        end

        # Destroy all instances of the resource on the remote API
        #
        # @raise [Error::UnavailableHost] when remote API cannot be connected to
        # @return [Array] array of resources destroyed
        def destroy_all
          all.each(&:destroy)
        end

        # Destroy all instances of the resource on the remote API, immediately raising
        # any errors encountered when processing the request against the remote API
        #
        # @raise [Error::UnavailableHost] when remote API cannot be connected to
        # @return [Array] array of resources destroyed
        def destroy_all!
          all.each(&:destroy!)
        end

      protected

        attr_reader :attributes

        def attr_accessor(*args)
          @attributes ||= []
          args.each do |arg|
            @attributes << arg
          end

          super(*args)
        end

        def use_host(host_text)
          raise Error::InvalidHost unless host_text.is_a?(String)
          unless host_text.match? URI::DEFAULT_PARSER.make_regexp(['http', 'https'])
            raise Error::InvalidHost
          end

          define_singleton_method(:host) do
            host_text.freeze
          end

          nil
        end

        def use_endpoint(endpoint_text)
          raise Error::InvalidEndpoint unless endpoint_text.is_a?(String)

          define_singleton_method(:endpoint) do
            endpoint_text.freeze
          end

          nil
        end

        def serialize_as(type_text)
          unless type_text.is_a?(Symbol) || type_text.is_a?(String)
            raise Error::InvalidSerializationType
          end

          define_singleton_method(:type) do
            type_text.to_sym.freeze
          end

          nil
        end

        def on_find_request_failed(exception, id)
          raise Error::NotFound, id if exception.status_symbol == :not_found
          raise exception if exception.status_symbol == :unrecognized_status_code
        end
      end

      # @param [Hash] attributes attributes for resource
      # @see ActiveModel::Base#initialize
      def initialize(attributes = {})
        super

        @state = :new
      end

      # Indicates if the resource is new (not yet persisted or destroyed). Only resources
      # created via .new and not yet saved (or destroyed) will be treated as new.
      #
      # @return [Boolean] true if resource is new; otherwise, false
      def new_record?
        @state == :new
      end

      # Indicates if the resource is persisted on the remote API.
      #
      # @return [Boolean] true if resource is persisted; otherwise, false
      def persisted?
        @state == :existing
      end

      # Indicates if the resource is destroyed on the remote API.
      #
      # @return [Boolean] true if resource has been destroyed; otherwise, false
      def destroyed?
        @state == :destroyed
      end

      # Assign an ID to the resource. This can only be done when the resource is not
      # persisted.
      #
      # @param [String] id ID of resource to retrieve
      # @raise [Error::InvalidIdArgument] if given ID is not a String
      # @raise [FrozenError] when resource is persisted or an ID previous assigned
      # @return [String] true if resource has been destroyed; otherwise, false
      def id=(id)
        (raise FrozenError, "can't modify id once persisted") if persisted?
        raise Error::InvalidIdArgument unless id.is_a?(String) && id&.match?(VALID_UUID_REGEXP)

        @id = id.freeze
        @id.freeze
      end

      # Returns the integer hash value for the resource based on its ID.
      #
      # @return [Integer] hash of resource
      def hash
        id.hash
      end

      # Saves current state of the resource using remote API
      #
      # @raise [Error::NotCreated] when creation of new resource fails on remote API
      # @raise [Error::NotUpdated] when update of existing resource fails on remote API
      # @raise [Error::UnavailableHost] when remote API cannot be connected to
      # @return [Boolean] true if resource saved successfully; otherwise, false
      def save
        persisted? ? update : create
      end

      # Saves current state of the resource using remote API, immediately raising any
      # errors encountered when processing the request against the remote API
      #
      # @raise [Error::ProhibitedCreation] when resource is not persisted, but already
      #   has an ID assigned
      # @raise [Error::ValidationsFailed] when resource does not pass validations
      # @raise [Error::UnavailableHost] when remote API cannot be connected to
      # @raise [Error::RequestFailed] for other request errors from remote API
      # @raise [Error::NotCreated] when created of new resource fails on remote API
      # @raise [Error::NotUpdated] when update of existing resource fails on remote API
      # @return [Boolean] true if resource saved successfully; otherwise, false
      def save!
        persisted? ? update! : create!
      end

      # Destroy resource on the remote API.
      #
      # @raise [Error::UnavailableHost] when remote API cannot be connected to
      # @return [Boolean] true if resource destroyed successfully; otherwise, false
      def destroy
        destroy!
      rescue Error::NotDestroyed,
             Error::RequestFailed => _e
        false
      end

      # Destroy resource on the remote API, immediately raising any errors encountered
      # when processing the request against the remote API
      #
      # @raise [Error::NotDestroyed] when record either has not been persisted or has no ID
      # @raise [Error::UnavailableHost] when remote API cannot be connected to
      # @raise [Error::RequestFailed] for other request errors from remote API
      # @return [Boolean] true if resource destroyed successfully; otherwise, false
      def destroy!
        raise Error::NotDestroyed unless persisted? && id?

        parse(connection.delete(path: "#{endpoint}/#{id}"))

        @state = :destroyed
        freeze

        true
      rescue Excon::Error::Socket => e
        on_socket_error(e)
      end

      # Equality comparison: returns true if `other` is the same object or is of the same
      # type with the same ID and all attributes are also equal.
      #
      # Also aliased as `eql?`.
      #
      # @return [Boolean] true if `other` is equal; otherwise, false
      def ==(other)
        other.equal?(self) ||
          (
            other.instance_of?(self.class) &&
            other.id == id &&
            other.attributes.all? do |attribute|
              other.public_send(attribute) == public_send(attribute)
            end
          )
      end

      # Equality comparison: returns true if `other` is the same object or is of the same
      # type with the same ID and all attributes are also equal
      #
      # Also aliased as `==`.
      #
      # @return [Boolean] true if `other` is equal; otherwise, false
      def eql?(other)
        self == (other)
      end

      # Freeze by cloning all attributes and freezing so that they are still accessible
      # even after destroying the resource.
      #
      # @return [Object] self
      def freeze
        @attributes = @attributes.clone.freeze
        super
        self
      end

      # Indicates if the resource and its attributes are frozen.
      #
      # @return [Boolean] true if frozen; otherwise, false
      def frozen?
        super && @attributes.frozen?
      end

    protected

      def endpoint
        raise Error::NoEndpointDefined unless self.class.respond_to?(:endpoint)

        @endpoint ||= self.class.endpoint
      end

      def id?
        @id.present?
      end

      def attributes
        self.class.__send__(:attributes)
      end

      def type
        raise Error::NoSerializationTypeDefined unless self.class.respond_to?(:type)

        self.class.__send__(:type)
      end

      def exists!
        @state = :existing
        self
      end

      def create
        create! || (raise Error::NotCreated)
      rescue JSONAPI::Model::Error::ValidationsFailed,
             JSONAPI::Model::Error::ProhibitedCreation,
             JSONAPI::Model::Error::RequestFailed
        false
      end

      def create!
        raise Error::ProhibitedCreation if persisted? || id?

        (raise Error::ValidationsFailed, errors) unless valid?

        result = parse(connection.post(path: endpoint, body: to_jsonapi))

        self.id = result['id']
        exists!

        true
      rescue Excon::Error::Socket => e
        on_socket_error(e)
      end

      def update
        update! || raise(Error::NotUpdated)
      rescue JSONAPI::Model::Error::ValidationsFailed,
             JSONAPI::Model::Error::RequestFailed => _e
        false
      end

      def update!
        raise Error::NotUpdated unless persisted? && id?

        (raise Error::ValidationsFailed, errors) unless valid?

        parse(connection.put(path: "#{endpoint}/#{id}", body: to_jsonapi))

        true
      rescue Excon::Error::Socket => e
        on_socket_error(e)
      end
    end
  end
end
