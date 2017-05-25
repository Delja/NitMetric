# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This module redef Mclassdef to add new collect methods.

module mclassdef_collect

# We usualy need specific phases
# NOTE: `frontend` is sufficent in most case (it is often too much)
import frontend

redef class MClassDef
	# Collect all mproperties introduced in 'self' with `visibility >= min_visibility`.
	fun collect_intro_mproperties: Set[MProperty] do
		var set = new HashSet[MProperty]
			for mprop in self.intro_mproperties do
				set.add(mprop)
			end
		return set
	end

	# Collect mmethods introduced in 'self' with `visibility >= min_visibility`.
	fun collect_intro_mmethods: Set[MMethod] do
		var res = new HashSet[MMethod]
		for mproperty in collect_intro_mproperties do
			if mproperty isa MMethod then res.add(mproperty)
		end
		return res
	end

	# Collect mattributes introduced in 'self' with `visibility >= min_visibility`.
	fun collect_intro_mattributes: Set[MAttribute] do
		var res = new HashSet[MAttribute]
		for mproperty in collect_intro_mproperties do
			if mproperty isa MAttribute then res.add(mproperty)
		end
		return res
	end
end