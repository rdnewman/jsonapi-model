RSpec.shared_context 'for deserialization' do
  let(:single_resource) do
    {
      data: {
        id: 1,
        type: 'note',
        attributes: {
          title: 'Title 1',
          date: '2015-12-20'
        },
        relationships: {
          author: {
            data: {
              type: 'user',
              id: 2
            }
          },
          second_author: {
            data: nil
          },
          notes: {
            data: [
              {
                type: 'note',
                id: 3
              },
              {
                type: 'note',
                id: 4
              }
            ]
          }
        }
      }
    }
  end

  let(:multiple_resources) do
    {
      data: [
        single_resource[:data],
        {
          id: 5,
          type: 'note',
          attributes: {
            title: 'Title 2',
            date: '2019-11-20'
          },
          relationships: {
            author: {
              data: {
                type: 'user',
                id: 6
              }
            },
            second_author: {
              data: nil
            },
            notes: {
              data: [
                {
                  type: 'note',
                  id: 7
                },
                {
                  type: 'note',
                  id: 8
                }
              ]
            }
          }
        },
        {
          id: 9,
          type: 'note',
          attributes: {
            title: 'Title 3',
            date: '2020-10-05'
          },
          relationships: {
            author: {
              data: {
                type: 'user',
                id: 10
              }
            },
            second_author: {
              data: nil
            },
            notes: {
              data: [
                {
                  type: 'note',
                  id: 11
                },
                {
                  type: 'note',
                  id: 12
                }
              ]
            }
          }
        }
      ]
    }
  end

  let(:expected_result) do
    {
      single: {
        resource: {
          'id' => 1,
          'date' => '2015-12-20',
          'title' => 'Title 1',
          'author_id' => 2,
          'second_author_id' => nil,
          'note_ids' => [3, 4]
        },
        only_notes: {
          'note_ids' => [3, 4]
        },
        except_data_or_title: {
          'id' => 1,
          'author_id' => 2,
          'second_author_id' => nil,
          'note_ids' => [3, 4]
        },
        only_polymorphic_author: {
          'author_id' => 2,
          'author_type' => 'User'
        }
      },
      multiple: {
        resources: [
          {
            'id' => 1,
            'date' => '2015-12-20',
            'title' => 'Title 1',
            'author_id' => 2,
            'second_author_id' => nil,
            'note_ids' => [3, 4]
          },
          {
            'id' => 5,
            'date' => '2019-11-20',
            'title' => 'Title 2',
            'author_id' => 6,
            'second_author_id' => nil,
            'note_ids' => [7, 8]
          },
          {
            'id' => 9,
            'title' => 'Title 3',
            'date' => '2020-10-05',
            'author_id' => 10,
            'second_author_id' => nil,
            'note_ids' => [11, 12]
          }
        ],
        only_notes: [
          { 'note_ids' => [3, 4] },
          { 'note_ids' => [7, 8] },
          { 'note_ids' => [11, 12] }
        ],
        except_data_or_title: [
          {
            'id' => 1,
            'author_id' => 2,
            'second_author_id' => nil,
            'note_ids' => [3, 4]
          },
          {
            'id' => 5,
            'author_id' => 6,
            'second_author_id' => nil,
            'note_ids' => [7, 8]
          },
          {
            'id' => 9,
            'author_id' => 10,
            'second_author_id' => nil,
            'note_ids' => [11, 12]
          }
        ],
        only_polymorphic_authors: [
          { 'author_id' => 2, 'author_type' => 'User' },
          { 'author_id' => 6, 'author_type' => 'User' },
          { 'author_id' => 10, 'author_type' => 'User' }
        ]
      }
    }
  end
end
