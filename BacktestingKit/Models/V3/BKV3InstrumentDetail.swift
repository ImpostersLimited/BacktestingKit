import Foundation

/// Represents `BKV3_InstrumentDetail` in the BacktestingKit public API.
public struct BKV3_InstrumentDetail: Codable, Equatable {
    public var Symbol: String
    public var AssetType: String
    public var Name: String
    public var Description: String
    public var CIK: Int
    public var Exchange: String
    public var Currency: String
    public var Country: String
    public var Sector: String
    public var Industry: String
    public var Address: String
    public var OfficialSite: String
    public var FiscalYearEnd: String
    public var LatestQuarter: String
    public var MarketCapitalization: Double
    public var EBITDA: Double
    public var PERatio: Double
    public var PEGRatio: Double
    public var BookValue: Double
    public var DividendPerShare: Double
    public var DividendYield: Double
    public var EPS: Double
    public var RevenuePerShareTTM: Double
    public var ProfitMargin: Double
    public var OperatingMarginTTM: Double
    public var ReturnOnAssetsTTM: Double
    public var ReturnOnEquityTTM: Double
    public var RevenueTTM: Double
    public var GrossProfitTTM: Double
    public var DilutedEPSTTM: Double
    public var QuarterlyEarningsGrowthYOY: Double
    public var QuarterlyRevenueGrowthYOY: Double
    public var AnalystTargetPrice: Double
    public var AnalystRatingStrongBuy: Double
    public var AnalystRatingBuy: Double
    public var AnalystRatingHold: Double
    public var AnalystRatingSell: Double
    public var AnalystRatingStrongSell: Double
    public var TrailingPE: Double
    public var ForwardPE: Double
    public var PriceToSalesRatioTTM: Double
    public var PriceToBookRatio: Double
    public var EVToRevenue: Double
    public var EVToEBITDA: Double
    public var Beta: Double
    public var _52WeekHigh: Double
    public var _52WeekLow: Double
    public var _50DayMovingAverage: Double
    public var _200DayMovingAverage: Double
    public var SharesOutstanding: Double
    public var DividendDate: String
    public var ExDividendDate: String
    public var Information: String

    enum CodingKeys: String, CodingKey {
        case Symbol, AssetType, Name, Description, CIK, Exchange, Currency, Country, Sector, Industry, Address, OfficialSite, FiscalYearEnd, LatestQuarter, MarketCapitalization, EBITDA, PERatio, PEGRatio, BookValue, DividendPerShare, DividendYield, EPS, RevenuePerShareTTM, ProfitMargin, OperatingMarginTTM, ReturnOnAssetsTTM, ReturnOnEquityTTM, RevenueTTM, GrossProfitTTM, DilutedEPSTTM, QuarterlyEarningsGrowthYOY, QuarterlyRevenueGrowthYOY, AnalystTargetPrice, AnalystRatingStrongBuy, AnalystRatingBuy, AnalystRatingHold, AnalystRatingSell, AnalystRatingStrongSell, TrailingPE, ForwardPE, PriceToSalesRatioTTM, PriceToBookRatio, EVToRevenue, EVToEBITDA, Beta, SharesOutstanding, DividendDate, ExDividendDate, Information
        case _52WeekHigh = "52WeekHigh"
        case _52WeekLow = "52WeekLow"
        case _50DayMovingAverage = "50DayMovingAverage"
        case _200DayMovingAverage = "200DayMovingAverage"
    }
}

