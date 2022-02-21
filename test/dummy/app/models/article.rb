class Article < ApplicationRecord
  has_many_attached :images
  has_many :comments, dependent: :destroy
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  accepts_nested_attributes_for :article_tags, allow_destroy: true

  validates :title, presence: true
  validates :content, presence: true
end
