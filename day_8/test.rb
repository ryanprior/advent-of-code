require_relative './solution.rb'

using SleighNavigationLicense

puts 'testing 0 1 0'
n, rem = SleighNavigationLicense.read_license('0 1 0')
p n.children.length.zero?
p n.meta.length == 1
p rem.length.zero?

puts 'testing 0 2 1 2'
n2, rem = SleighNavigationLicense.read_license('0 2 1 2')
p n2.children.length.zero?
p n2.meta.length == 2
p n2.meta == [1, 2]
p rem.length.zero?

puts 'testing 1 1 0 1 0 0'
n3, rem = SleighNavigationLicense.read_license('1 1 0 1 0 0')
p n3.children.length == 1
p n3.meta.length == 1
c3 = n3.dig(:children, 0, :children)
p c3.length.zero? if c3
p n3.dig(:children, 0, :meta) == [0]
p n3.meta == [0]
p rem.length.zero?

puts 'testing 2 1 0 1 0 0 1 0 99'
n4, rem = SleighNavigationLicense.read_license('2 1 0 1 0 0 1 0 99')
p n4.children.length == 2
p n4.meta.length == 1
p rem.length.zero?

puts 'testing easy input: 2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2'
n5, rem = SleighNavigationLicense.read_license('2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2')
p n5.children.length == 2
p n5.meta.length == 3
p n5.all_metadata.flatten.sum == 138
p rem.length.zero?
