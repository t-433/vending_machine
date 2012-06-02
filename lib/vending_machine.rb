# -*- coding: utf-8 -*-
module Money
  class Money 
    attr :value

    def initialize(value)
      @value = value
    end
  end

  ONE = Money.new(1)
  FIVE = Money.new(5)
  TEN = Money.new(10)
  FIFTY = Money.new(50)
  HUNDRED = Money.new(100)
  FIVE_HUNDRED = Money.new(500)
  THOUSAND = Money.new(1000)
end

class MoneyStock
  attr :money
  attr_accessor :stock

  def initialize(money, stock)
    @money = money
    @stock = stock
  end

  def ==(other)
    @money == other.money && @stock == other.stock
  end

end


module Drink
  class Drink
    attr :id
    attr :name
    attr :value

    def initialize(id, name, value)
      @id = id
      @name = name
      @value = value
    end
  end

  COKE = Drink.new(1, "コーラ", 120)
  RED_BULL = Drink.new(2, "レッドブル", 200)
  WATER = Drink.new(3, "水", 100)
end

class DrinkStock
  attr :drink
  attr_accessor :stock

  def initialize(drink, stock)
    @drink = drink
    @stock = stock
  end

  def ==(other)
    @drink == other.drink && @stock == other.stock
  end

end

class DrinkNumber
  attr :drink
  attr_accessor :number

  def initialize(drink, number)
    @drink = drink
    @number = number
  end

  def ==(other)
    @drink == other.drink && @number == other.number
  end

end


class VendingMachine
  attr :valid_monies
  attr :money_stocks 
  attr :drop_in_money_stocks 
  attr :drink_stocks 
  attr :bingo_drink_numbers
  attr :earnings
  attr_accessor :bingo_on

  def initialize
    @valid_moneis = [Money::TEN, Money::FIFTY, Money::HUNDRED, Money::FIVE_HUNDRED, Money::THOUSAND]
    @money_stocks = @valid_moneis.map {|money| MoneyStock.new(money, 0)}
    @drop_in_money_stocks = @valid_moneis.map {|money| MoneyStock.new(money, 0)}
    @drink_stocks = [DrinkStock.new(Drink::COKE, 0), DrinkStock.new(Drink::RED_BULL, 0), DrinkStock.new(Drink::WATER, 0)]
    @bingo_drink_numbers = [DrinkNumber.new(Drink::COKE, 0), DrinkNumber.new(Drink::RED_BULL, 0), DrinkNumber.new(Drink::WATER, 0)]
    @earnings = 0
    @bingo_on = false
  end

  def refill_money_stock(money, stock) 
    find_money_stock(money).stock += stock
  end

  def change?(change)
    change_helper(change)[0]
  end

  def changes(change)
    change_helper(change)[1]
  end

  def new_money_stock_after_change(change)
    change_helper(change)[2]
  end

  def change_helper(change)
    current_total_money_stocks = create_current_total_money_stocks
    new_money_stock = []

    changes = []
    remainder = change 
    @valid_moneis.reverse.each {|money|
      quotient = remainder / money.value
      current_money_stock = current_total_money_stocks.find { |money_stock| money_stock.money == money }.stock
      use_money_stock = [quotient, current_money_stock].min
      changes << MoneyStock.new(money, use_money_stock) if use_money_stock > 0
      new_money_stock << MoneyStock.new(money, current_money_stock - use_money_stock)
      remainder -= (money.value * use_money_stock)
    }
    [remainder == 0, changes, new_money_stock.reverse]
  end


  def create_current_total_money_stocks
    @money_stocks.zip(@drop_in_money_stocks).map {|item| 
      MoneyStock.new(item[0].money, item[0].stock + item[1].stock) 
    }
  end

  def find_money_stock(money)
    @money_stocks.find { |money_stock| money_stock.money == money }
  end

  def amount_of_money_stocks
    @money_stocks.inject(0) { |amount, money_stock| amount += money_stock.money.value * money_stock.stock }
  end

  def amount_of_drop_in
    @drop_in_money_stocks.inject(0) { |amount, drop_in_money_stock| amount += drop_in_money_stock.money.value * drop_in_money_stock.stock }
  end

  def drop_in(*moneis)
    moneis.each { |money| raise ArgumentError, money.value unless @valid_moneis.include?(money) }

    moneis.each { |money| find_drop_in_money_stock(money).stock += 1 } 
  end

  def find_drop_in_money_stock(money)
    @drop_in_money_stocks.find { |money_stock| money_stock.money == money }
  end

  def refill_drink_stock(drink, number_of_pieces) 
    find_drink_stock(drink).stock += number_of_pieces
  end

  def drink_stock?(drink)
    find_drink_stock(drink).stock > 0
  end

  def drink_stock(drink)
    find_drink_stock(drink).stock 
  end

  def find_drink_stock(drink)
    @drink_stocks.find { |drink_stock| drink_stock.drink == drink }
  end

  def purchaseable_drinks
    @drink_stocks.inject([]) { |drinks, drink_stock| 
      drinks << drink_stock.drink if drink_stock?(drink_stock.drink) && drink_stock.drink.value <= amount_of_drop_in() && change?(amount_of_drop_in - drink_stock.drink.value)
      drinks
    }
  end

  def purchase?(drink)
    purchaseable_drinks.include?(drink)
  end

  def changes_if_purchase(drink)
    changes(amount_of_drop_in - drink.value) if purchase?(drink)
  end

  def cancel 
    drop_in_monies_for_cancel = @drop_in_money_stocks.map {|drop_in_money_stock| MoneyStock.new(drop_in_money_stock.money, drop_in_money_stock.stock) }
    @drop_in_money_stocks.each { |drop_in_money_stock| drop_in_money_stock.stock = 0 }
    drop_in_monies_for_cancel 
  end

  def purchase(drink) 
    raise ArgumentError, drink unless purchase?(drink)

    changes = changes_if_purchase(drink)
    @money_stocks = new_money_stock_after_change(amount_of_drop_in - drink.value)
    @drop_in_money_stocks.each { |drop_in_money_stock| drop_in_money_stock.stock = 0 }

    find_bingo_drink_number(drink).number += 1 if bingo?(drink)
    find_drink_stock(drink).stock = drink_stock(drink) - (bingo?(drink) ? 2 : 1)

    @earnings += drink.value
    changes
  end

  def find_bingo_drink_number(drink)
    @bingo_drink_numbers.find { |drink_number| drink_number.drink == drink }
  end


  def bingo?(drink)
    bingo_on && drink_stock(drink) >= 2 && rand100 < 5
  end

  def rand100
    rand(100)
  end

  def amount_of_bingos
    @bingo_drink_numbers.inject(0) { |amount, bingo_drink_number| amount += bingo_drink_number.drink.value * bingo_drink_number.number }
  end

end
