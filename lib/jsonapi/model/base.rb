require 'jsonapi/model/connectable'

module JSONAPI
  module Model
    # Base class to inherit specific models based on working with remote JSONAPI endpoints
    class Base
      include ActiveModel::Model
      include Connectable

      VALID_UUID_REGEXP = /\h{8}-\h{4}-4\h{3}-[89AB]\h{3}-\h{12}/i.freeze # version 4, non-null

      attr_reader :id

      validates :id,
                presence: true,
                format: { with: VALID_UUID_REGEXP, message: 'invalid UUID format' },
                if: :persisted?

      class << self
        def find(id = nil)
          raise Error::NoEndpointDefined unless respond_to?(:endpoint)
          raise Error::InvalidIdArgument unless id.is_a?(String) && id&.match?(VALID_UUID_REGEXP)

          new(parse(connection.get(path: "#{endpoint}/#{id}"))).tap do |obj|
            obj.__send__(:exists!)
          end
        rescue Error::RequestFailed => e
          e.status_symbol == :not_found ? (raise Error::NotFound, id) : nil
        rescue Excon::Error::Socket => e
          on_socket_error(e)
        end
        alias_method :[], :find

        def all
          raise Error::NoEndpointDefined unless respond_to?(:endpoint)

          parse(connection.get(path: endpoint)).map do |attributes|
            new(attributes).tap { |obj| obj.__send__(:exists!) }
          end
        rescue Excon::Error::Socket => e
          on_socket_error(e)
        end

        def create(attributes = {})
          raise Error::NoEndpointDefined unless respond_to?(:endpoint)

          object = new(attributes.except(:id))
          result = object.__send__(:create)
          result ? object.id : (raise Error::NotCreated)
        end

        def create!(attributes = {})
          raise Error::NoEndpointDefined unless respond_to?(:endpoint)

          object = new(attributes.except(:id))
          result = object.__send__(:create!)
          result ? object.id : (raise Error::NotCreated)
        end

        def destroy_all
          all.each(&:destroy)
        end

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
            raise Error::InvalidSerailizeType
          end

          define_singleton_method(:type) do
            type_text.to_sym.freeze
          end

          nil
        end
      end

      def initialize(params = {})
        super

        @state = :new
      end

      def new_record?
        @state == :new
      end

      def persisted?
        @state == :existing
      end

      def destroyed?
        @state == :destroyed
      end

      def id=(id)
        (raise FrozenError, "can't modify id once persisted") if persisted?
        raise Error::InvalidIdArgument unless id.is_a?(String) && id&.match?(VALID_UUID_REGEXP)

        @id = id.freeze
        @id.freeze
      end

      def hash
        id.hash
      end

      def save
        persisted? ? update : create
      end

      def save!
        persisted? ? update! : create!
      end

      def destroy
        destroy!
      rescue Error::NotDestroyed,
             Error::RequestFailed => _e
        false
      end

      def destroy!
        raise Error::NotDestroyed unless persisted? && id?

        parse(connection.delete(path: "#{endpoint}/#{id}"))

        @state = :destroyed
        freeze

        true
      rescue Excon::Error::Socket => e
        on_socket_error(e)
      end

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

      def eql?(other)
        self == (other)
      end

      def freeze
        @attributes = @attributes.clone.freeze
        super
        self
      end

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
        self.class.__send__(:type)
      rescue NoMethodError
        raise Error::NoSerializationTypeDefined
      end

      def exists!
        @state = :existing
        self
      end

      def create
        create! || (raise Error::NotCreated)
      rescue JSONAPI::Model::Error::ValidationsFailed,
             JSONAPI::Model::Error::ProhibitedCreation,
             JSONAPI::Model::Error::RequestFailed => _e
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
