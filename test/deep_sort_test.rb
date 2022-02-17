require "test_helper"
require "full_metal_body/deep_sort"

using FullMetalBody::DeepSort

class FullMetalBody::DeepSortTest < ActiveSupport::TestCase

  test "it should be sortable with a simple hash." do
    hash = { e: 1, d: 2, c: 3, b: 4, a: 5 }
    assert_equal({ a: 5, b: 4, c: 3, d: 2, e: 1 }, hash.deep_sort)
    assert_equal({ e: 1, d: 2, c: 3, b: 4, a: 5 }, hash)
    hash.deep_sort!
    assert_equal({ a: 5, b: 4, c: 3, d: 2, e: 1 }, hash)
  end

  test 'it should be sortable with a nested hash.' do
    hash = { e: 1, d: { c: 1, b: { i: 4, f: 1, h: 3, g: 2 } }, a: 1 }
    assert_equal({ a: 1, d: { b: { f: 1, g: 2, h: 3, i: 4 }, c: 1 }, e: 1 }, hash.deep_sort)
  end

  test 'it should be sortable with a hash that includes array.' do
    hash = { d: [3, 1, 2], c: [8, 7, 9], b: 4, a: 5 }
    assert_equal({ a: 5, b: 4, c: [7, 8, 9], d: [1, 2, 3] }, hash.deep_sort)
  end

  test 'it should be sortable with a hash that is complicated.' do
    hash = {
      e: { c: [3, 1, 2], b: [7, 2, 4] },
      a: [{ k: 1, h: 1, j: 1, i: 1 }, { g: 1, f: 2 }],
      m: [5, 1, 3],
    }
    assert_equal({
      a: [{ f: 2, g: 1 }, { h: 1, i: 1, j: 1, k: 1 }],
      e: { b: [2, 4, 7], c: [1, 2, 3] },
      m: [1, 3, 5],
    }, hash.deep_sort)
  end

  test 'it raise an error when the hash key of type definition is not string or symbol or numeric.' do
    hash = {
      [1, 2] => 1,
      "a" => 2,
      c: 3,
    }
    assert_raise FullMetalBody::DeepSort::Error do
      hash.deep_sort
    end
  end
end
