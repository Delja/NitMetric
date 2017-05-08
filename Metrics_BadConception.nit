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

# Example of simple module that aims to do some specific work on nit programs.
#
# Fast prototypes can just start with this skeletton.
module test_test_phase

# We need the framework that perfoms standard code for the main-program
import test_phase

# We usualy need specific phases
# NOTE: `frontend` is sufficent in most case (it is often too much)
import frontend

# The body of the specific work.
# The main entry point is provided by `test_phase`,
# This function is then automatically (unless errors where found).
redef fun do_work(mainmodule, given_mmodules, modelbuilder)
do
	var model = modelbuilder.model
	var mclasses = mainmodule.flatten_mclass_hierarchy

	#New array of classedef
	var mclassdef = new Array [MClassDef]

	#New array of classe
	var mclasse = new Array [MClass]

	# search all class and classdef and put they in the array
	for m in mclasses do
		mclasse.add(m)
		for cd in m.mclassdefs do
			mclassdef.add(cd)
		end
	end


	# Execute antipattern detection
	for m in mclassdef do
		print "Class : {m.name}"
		m.mclassantipatterns.collect(m)
		m.mclasscodesmell.collect(m)
		m.mclassantipatterns.printAll
		m.mclasscodesmell.printAll
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

	#Colection
	fun collect(classe : MClassDef)do 
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
	fun collect(classe : MClassDef)do end

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

	redef fun collect(classe) do
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

	redef fun collect(classe) do
		for meth in classe.mpropdefs do
			if meth isa MMethodDef then
				if meth.msignature != null then
					if meth.msignature.mparameters  != null then
						if meth.msignature.mparameters.length >= 4 then 
							badmethode.add(meth)
							result = true
						end
					end
				end
			end
		end
	end


	redef fun printResult do
		print "{desc} :  {result}"
		if badmethode.length >= 1 then print "   Affected method :"
		for methode in badmethode do 
			print "    {methode.name}"
		end
	end
end

# Not implemented
class GOC
	super Antipattern

	# Name
	redef fun name do 
		return "Goc"
	end

	#Description
	redef fun desc do 
		return "God of class"
	end

	#Collection method
	redef fun collect(classe : MClassDef) do
		
	end
end

#Not implemented
# Dans cette formule I représente le nombre d’attributs de la classe, 
# K le nombre de méthodes et A représente la somme du nombre d’attribut accédé par chaque méthode.
class LCOM5
	#Init Result
	var result = 0

	init(l: Int, k : Int, a :Int) do
		result = (a - k) / (l - k) 
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
	fun collect_intro_mattributes(): Set[MAttribute] do
		var res = new HashSet[MAttribute]
		for mproperty in collect_intro_mproperties do
			if mproperty isa MAttribute then res.add(mproperty)
		end
		return res
	end
end