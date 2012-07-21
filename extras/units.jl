# Support for physical units: I/O and conversion
# Timothy E. Holy, 2012

abstract SIPrefix
type Yocto <: SIPrefix end
type Zepto <: SIPrefix end
type Atto <: SIPrefix end
type Femto <: SIPrefix end
type Pico <: SIPrefix end
type Nano <: SIPrefix end
type Micro <: SIPrefix end
type Milli <: SIPrefix end
type Centi <: SIPrefix end
type Deci <: SIPrefix end
type SINone <: SIPrefix end
type Deca <: SIPrefix end
type Hecto <: SIPrefix end
type Kilo <: SIPrefix end
type Mega <: SIPrefix end
type Giga <: SIPrefix end
type Tera <: SIPrefix end
type Peta <: SIPrefix end
type Exa <: SIPrefix end
type Zetta <: SIPrefix end
type Yotta <: SIPrefix end

# PrettyShow
pshow(x) = pshow(OUTPUT_STREAM::IOStream, x)
# LatexShow
lshow(x) = lshow(OUTPUT_STREAM::IOStream, x)
# FullShow
fshow(x) = fshow(OUTPUT_STREAM::IOStream, x)

let
#  Prefix        ToSINone      Show          PrettyShow   LatexShow  Full
const prefix_table = {
  (Yocto,        1e-24,        "y",          "y",         "y",       "yocto")
  (Zepto,        1e-21,        "z",          "z",         "z",       "zepto")
  (Atto,         1e-18,        "a",          "a",         "a",       "atto")
  (Femto,        1e-15,        "f",          "f",         "f",       "femto")
  (Pico,         1e-12,        "p",          "p",         "p",       "pico")
  (Nano,         1e-9,         "n",          "n",         "n",       "nano")
  (Micro,        1e-6,         "u",          "\u03bc",   L"$\mu$",   "micro")
  (Milli,        1e-3,         "m",          "m",         "m",       "milli")
  (Centi,        1e-2,         "c",          "c",         "c",       "centi")
  (Deci,         1e-1,         "d",          "d",         "d",       "deci")
  (Deca,         1e1,          "da",         "da",        "da",      "deca")
  (Hecto,        1e2,          "h",          "h",         "h",       "hecto")
  (Kilo,         1e3,          "k",          "k",         "k",       "kilo")
  (Mega,         1e6,          "M",          "M",         "M",       "mega")
  (Giga,         1e9,          "G",          "G",         "G",       "giga")
  (Tera,         1e12,         "T",          "T",         "T",       "tera")
  (Peta,         1e15,         "P",          "P",         "P",       "peta")
  (Exa,          1e18,         "E",          "E",         "E",       "exa")
  (Zetta,        1e21,         "Z",          "Z",         "Z",       "zetta")
  (Yotta,        1e24,         "Y",          "Y",         "Y",       "yotta")
}
global to_reference
global show
global pshow
global lshow
global _unit_si_prefixes
for (t, f, s, ps, ls, fs) in prefix_table
    @eval to_reference(::Type{$t}) = $f
    @eval show(io, ::Type{$t}) = print(io, $s)
    @eval pshow(io, ::Type{$t}) = print(io, $ps)
    @eval lshow(io, ::Type{$t}) = print(io, $ls)
    @eval fshow(io, ::Type{$t}) = print(io, $fs)
end
function return_prefix(i::Int)
    if i <= length(prefix_table)
        return prefix_table[i][1]
    elseif i == length(prefix_table)+1
        return SINone
    else
        error("Something is wrong")
    end
end
_unit_si_prefixes = ntuple(length(prefix_table)+1, i->return_prefix(i))
end  # let
to_reference(::Type{SINone}) = 1
show(io, ::Type{SINone}) = nothing
pshow(io, ::Type{SINone}) = nothing
lshow(io, ::Type{SINone}) = nothing
fshow(io, ::Type{SINone}) = nothing

# Units
abstract UnitBase
type Unit{TP<:SIPrefix, TU<:UnitBase} end
Unit{TP<:SIPrefix, TU<:UnitBase}(tp::Type{TP}, tu::Type{TU}) = Unit{tp, tu}
Unit{TU<:UnitBase}(tu::Type{TU}) = Unit{SINone, tu}
function show{TP<:SIPrefix, TU<:UnitBase}(io, tu::Unit{TP, TU})
    print(io, TP)
    print(io, TU)
end

# Values with units
type Quantity{TP<:SIPrefix, TU<:UnitBase, Tdata}
    value::Tdata
end
Quantity{TP<:SIPrefix, TU<:UnitBase, Tdata}(tp::Type{TP}, tu::Type{TU}, val::Tdata) = Quantity{tp, tu, Tdata}(val)
Quantity{TU<:UnitBase, Tdata}(tu::Type{TU}, val::Tdata) = Quantity{SINone, tu, Tdata}(val)
prefix{TP<:SIPrefix, TU<:UnitBase, Tdata}(q::Quantity{TP, TU, Tdata}) = TP
base{TP<:SIPrefix, TU<:UnitBase, Tdata}(q::Quantity{TP, TU, Tdata}) = TU

function show{TP<:SIPrefix, TU<:UnitBase}(io, q::Quantity{TP, TU})
    print(io, q.value, " ")
    show(io, TP)
    show(io, TU)
end
function pshow{TP<:SIPrefix, TU<:UnitBase}(io, q::Quantity{TP, TU})
    print(io, q.value, " ")
    pshow(io, TP)
    pshow(io, TU)
end
function lshow{TP<:SIPrefix, TU<:UnitBase}(io, q::Quantity{TP, TU})
    print(io, q.value, " ")
    lshow(io, TP)
    lshow(io, TU)
end
function fshow{TP<:SIPrefix, TU<:UnitBase}(io, q::Quantity{TP, TU})
    print(io, q.value, " ")
    fshow(io, TP)
    fshow(io, TU)
end

# Functions and dictionaries for parsing
_unit_string_dict = Dict{ASCIIString, Tuple}()

function _unit_gen_func_multiplicative(table)
    for (t, r, to_r, s, ps, ls, fs) in table
        @eval reference(::Type{$t}) = $r
        @eval to_reference(::Type{$t}) = x->x*$to_r
        @eval from_reference(::Type{$t}) = x->x/$to_r
        @eval show(io, ::Type{$t}) = print(io, $s)
        @eval pshow(io, ::Type{$t}) = print(io, $ps)
        @eval lshow(io, ::Type{$t}) = print(io, $ls)
        @eval fshow(io, ::Type{$t}) = print(io, $fs)
    end
end

function _unit_gen_func(table)
    for (t, r, to_func, from_func, s, ps, ls, fs) in table
        @eval reference(::Type{$t}) = $r
        @eval to_reference(::Type{$t}) = $to_func
        @eval from_reference(::Type{$t}) = $from_func
        @eval show(io, ::Type{$t}) = print(io, $s)
        @eval pshow(io, ::Type{$t}) = print(io, $ps)
        @eval lshow(io, ::Type{$t}) = print(io, $ls)
        @eval fshow(io, ::Type{$t}) = print(io, $fs)
    end
end


function _unit_gen_dict_with_prefix(table)
    for (u, rest) in table
        for p in _unit_si_prefixes
            key = string(p)*string(u)
#            println(key, ": ", p, ", ", u) 
            _unit_string_dict[key] = (p, u)
        end
    end
end

function _unit_gen_dict(table)
    for (u, rest) in table
        key = string(u)
#        println(key, ": ", u) 
        _unit_string_dict[key] = (SINone, u)
    end
end


# Length units
type Meter <: UnitBase end
type Angstrom <: UnitBase end
type Inch <: UnitBase end
type Foot <: UnitBase end
type Yard <: UnitBase end
type Mile <: UnitBase end
type LightYear <: UnitBase end
type Parsec <: UnitBase end
type AstronomicalUnit <: UnitBase end
let
  # Unit     RefUnit    ToRef            show      pshow     lshow   fshow
const utable = {
  (Meter,    Meter,    1,                "m",      "m",      "m",    "meter")
  (Angstrom, Meter,    1e-10,            "A",      "\u212b",L"$\AA$","angstrom")
  (Inch,     Meter,    25.4/1000,        "in",     "in",     "in",   "inch")
  (Foot,     Meter,    12*25.4/1000,     "ft",     "ft",     "ft",   "foot")
  (Yard,     Meter,    36*25.4/1000,     "yd",     "yd",     "yd",   "yard")
  (Mile,     Meter,    5280*12*25.4/1000,"mi",     "mi",     "mi",   "mile")
  (LightYear,Meter,    9.4605284e15,     "ly",     "ly",     "ly",   "lightyear")
  (Parsec,   Meter,    3.08568025e16,    "pc",     "pc",     "pc",   "parsec")
  (AstronomicalUnit, Meter, 149_597_870_700, "AU", "AU",     "AU",   "astronomical unit")
}
_unit_gen_func_multiplicative(utable)
_unit_gen_dict_with_prefix({utable[1]})  # parse prefixes only for Meter
_unit_gen_dict(utable[2:end])
end

# Time units
type Second <: UnitBase end
type Minute <: UnitBase end
type Hour <: UnitBase end
type Day <: UnitBase end
type Week <: UnitBase end
type YearJulian <: UnitBase end
type PlanckTime <: UnitBase end
let
  # Unit       RefUnit     ToRef            show      pshow     lshow  fshow
const utable = {
  (Second,     Second,      1,             "s",      "s",      "s",    "second")
  (Minute,     Second,      60,            "min",    "min",    "min",  "minute")
  (Hour,       Second,      3600,          "hr",     "hr",     "hr",   "hour")
  (Day,        Second,      86400,         "d",      "d",      "d",    "day")
  (YearJulian, Second,      365.25*86400,  "yr",     "yr",     "yr",   "year")
  (PlanckTime, Second,      5.3910632e-44, "tP",     "tP",    L"$t_P$","Planck time")
}
_unit_gen_func_multiplicative(utable)
_unit_gen_dict_with_prefix({utable[1]})   # prefixes are only common for seconds
_unit_gen_dict(utable[2:end])
end

# Rate units
type Herz <: UnitBase end
let
  # Unit       RefUnit     ToRef        show      pshow     lshow   fshow
const utable = {
  (Herz,       Herz,        1,          "Hz",     "Hz",     "Hz",   "Herz")
}
_unit_gen_func_multiplicative(utable)
_unit_gen_dict_with_prefix(utable)
end

# Mass units
# (note English units like pounds are technically weight, not mass)
type Gram <: UnitBase end
type AtomicMassUnit <: UnitBase end
type Dalton <: UnitBase end
type PlanckMass <: UnitBase end
let
  # Unit       RefUnit     ToRef           show      pshow     lshow  fshow
const utable = {
  (Gram,       Gram,        1,             "g",      "g",      "g",   "gram")
  (AtomicMassUnit, Gram,    1.66053892173e-24, "amu","amu",    "amu", "atomic mass unit")
  (Dalton,     Gram,        1.66053892173e-24, "Da", "Da",     "Da",  "Dalton")
  (PlanckMass, Gram,        2.1765113e-5,  "mP",     "mP",    L"$m_P$","Planck mass")
}
_unit_gen_func_multiplicative(utable)
_unit_gen_dict_with_prefix({utable[1]})
_unit_gen_dict(utable[2:end])
end

# Electric current units
type Ampere <: UnitBase end
let
  # Unit       RefUnit     ToRef        show      pshow     lshow   fshow
const utable = {
  (Ampere,     Ampere,     1,           "A",      "A",      "A",   "ampere")
}
_unit_gen_func_multiplicative(utable)
_unit_gen_dict_with_prefix(utable)
end


# Temperature units
# The conversions for these are not just a product
type Kelvin <: UnitBase end
type Celsius <: UnitBase end
type Fahrenheit <: UnitBase end
let
  # Unit       RefUnit  ToRef              FromRef     show    pshow  lshow  fshow
const utable = {
  (Kelvin,     Kelvin,  x->x,              x->x,       "K",    "K",   "K",   "Kelvin")
  (Celsius,    Kelvin,  x->x+273.15,       x->x-273.15,"C",    "C",   "C",   "Celsius")
  (Fahrenheit, Kelvin,  x->(x+459.67)*5/9, x->x*9/5-459.67,"F","F",   "F",   "Fahrenheit")
}
_unit_gen_func(utable)
_unit_gen_dict_with_prefix({utable[1]})   # prefixes are only common for Kelvin
_unit_gen_dict(utable[2:end])
end

# Luminosity units
type Candela <: UnitBase end
let
  # Unit       RefUnit     ToRef        show      pshow     lshow   fshow
const utable = {
  (Candela,    Candela,    1,           "cd",     "cd",     "cd",   "candela")
}
_unit_gen_func_multiplicative(utable)
_unit_gen_dict_with_prefix(utable)
end


# Amount units
type Mole <: UnitBase end
type Entities <: UnitBase end
let
  # Unit       RefUnit     ToRef        show      pshow     lshow   fshow
const utable = {
  (Mole,       Mole,       1,           "mol",    "mol",    "mol",  "mole")
  (Entities,   Mole,       1/6.0221417930e23, "", "",       "",     "entities")
}
_unit_gen_func_multiplicative(utable)
_unit_gen_dict_with_prefix({utable[1]})
end


# Parsing string to extract Quantity
function parse_quantity(s::String)
    m = match(r"[a-zA-Z]", s)
    if m.offset < 1
        error("String does not have a 'value unit' structure")
    end
    val = parse_float(Float64, strip(s[1:m.offset-1]))
    (prefix, unit) = _unit_string_dict[strip(s[m.offset:end])]
    return Quantity(prefix, unit, val)
end


# Conversion between units
function convert{Uin<:UnitBase, Uout<:UnitBase, Pin<:SIPrefix, Pout<:SIPrefix, T}(::Type{Unit{Pout, Uout}}, q::Quantity{Pin, Uin, T})
    if reference(Uin) != reference(Uout)
        error("Not convertable")
    end
    return Quantity(Pout, Uout, from_reference(Uout)(to_reference(Uin)(q.value*to_reference(Pin))) / to_reference(Pout))
end
