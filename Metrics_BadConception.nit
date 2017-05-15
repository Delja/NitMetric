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


# We need the framework that perfoms standard code for the main-program
import test_phase

# We usualy need specific phases
# NOTE: `frontend` is sufficent in most case (it is often too much)
import frontend

import metrics_base
import mclasses_metrics
import semantize

import method_analyse_metrics

# The body of the specific work.
# The main entry point is provided by `test_phase`,
# This function is then automatically (unless errors where found).
redef fun do_work(mainmodule, given_mmodules, modelbuilder)
do
	var model = modelbuilder.model
	var mclasses = mainmodule.flatten_mclass_hierarchy


	#New array of classedef
	var aclassdefs = new Array [AClassdef]

	#New array of classe
	var mclasse = new Array [MClass]

	# search all class and classdef and put they in the array
	for m in mclasses do
		mclasse.add(m)
	end

	for nmodule in modelbuilder.nmodules do
		for nclassdef in nmodule.n_classdefs do
			aclassdefs.add(nclassdef)
		end
	end


	for aclassdef in aclassdefs do
		# Execute antipattern detection
		var m = aclassdef.mclassdef
		if m != null then
			print "Class : {m.name}"
			m.mclassantipatterns.collect(aclassdef)
			m.mclasscodesmell.collect(aclassdef)
			m.mclassantipatterns.printAll
			m.mclasscodesmell.printAll
		end		
	end
end

class BadConceptions
	#Code smell list
	var badConceptionElement = new Array[BadConception]

	# Print all element conception
	fun printAll do
		for cd in badConceptionElement do
			cd.printResult
		end
	end

	#Collection
	fun collect(classe : AClassdef)do 
		for cd in badConceptionElement do
			cd.collect(classe)
		end 
	end
end

class Antipatterns
	super BadConceptions
	# create all Antipatterns
	init do
		#badConceptionElement.add(new GOC)
	end
end

class CodeSmells
	super BadConceptions
	# create all codesmells	
	init do
		badConceptionElement.add(new LARGC)
		badConceptionElement.add(new LONGPL)
		badConceptionElement.add(new FEM)
		badConceptionElement.add(new LONGMETH)
	end
end



class BadConception
	#Bool Result
	var result = false

	#Name
	fun name: String do 
		return ""
	end

	#Description
	fun desc: String do 
		return ""
	end

	#Collection method
	fun collect(classe : AClassdef)do end

	#Show results in console
	fun printResult do
		print "{desc} :  {result}"
	end
end


class Antipattern
	super BadConception
end


class CodeSmell
	super BadConception
end


class LARGC
	super CodeSmell

	redef fun name do 
		return "LARGC"
	end
	redef fun desc do 
		return "Large class"
	end

	redef fun collect(aclasse) do

		#get class definition 
		var classe = aclasse.mclassdef
		var numberAttribut = classe.collect_intro_mattributes.length
		#get the number of methods and subtract the get and set of attibutes (numberAtribut*2)
		var numberMethode = classe.collect_intro_mattributes.length - (numberAttribut*2)
		if numberMethode > 20 or numberAttribut > 20 then result = true
	end
end

class LONGPL
	super CodeSmell

	var badmethode = new Array[MMethodDef] 

	redef fun name do 
		return "LONGPL"
	end
	redef fun desc do 
		return "Long parameter list"
	end

	redef fun collect(aclasse) do
		#get class definition 
		var classe = aclasse.mclassdef
		for meth in classe.mpropdefs do
			#check if the property is a method definition
			if meth isa MMethodDef then
				#Check if method has a signature
				if meth.msignature != null then
					if meth.msignature.mparameters.length >= 4 then 
						badmethode.add(meth)
						result = true
					end
				end
			end
		end
	end


	redef fun printResult do
		print "{desc} :  {result}"
		if badmethode.length >= 1 then 
			print "   Affected method :"
			for methode in badmethode do 
				print "    {methode.name}"
			end
		end
	end
end


class FEM
	super CodeSmell

	var badmethode = new Array[AIdMethid] 

	redef fun name do 
		return "FEM"
	end
	redef fun desc do 
		return "Feature envy"
	end

	redef fun collect(aclasse) do

		#Call the visit class method
		var visits = callvisiteMethodAnalyse(aclasse)

		for visit in visits do
			if visit.total_call.length < visit.total_call_self.length then
				result = true
				badmethode.add(visit.nclassdef.n_methid.as(AIdMethid))
			end
		end

	end


	redef fun printResult do
		print "{desc} :  {result}"
		if badmethode.length >= 1 then 
			print "   Affected method :"
			for methode in badmethode do 
				print "    {methode.n_id.text}"
			end
		end
	end
end

class LONGMETH
	super CodeSmell

	var badmethode = new Array[AIdMethid] 

	redef fun name do 
		return "LONGMETH"
	end
	redef fun desc do 
		return "Long method"
	end

	redef fun collect(aclasse) do
		var visits = callvisiteMethodAnalyse(aclasse)

		for visit in visits do
			if visit.lineDetail.length > 30 then
				result = true
				badmethode.add(visit.nclassdef.n_methid.as(AIdMethid))
			end
		end
	end


	redef fun printResult do
		print "{desc} :  {result}"
		if badmethode.length >= 1 then 
			print "   Affected method :"
			for methode in badmethode do 
				print "    {methode.n_id.text}"
			end
		end
	end
end



redef class MClassDef
	var mclassantipatterns = new Antipatterns
	var mclasscodesmell = new CodeSmells

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