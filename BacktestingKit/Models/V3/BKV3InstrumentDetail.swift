import Foundation

/// Represents `BKV3_InstrumentDetail` in the BacktestingKit public API.
public struct BKV3_InstrumentDetail: Codable, Equatable {
    /// Symbol associated with this value.
    public var Symbol: String
    /// Asset type associated with this value.
    public var AssetType: String
    /// Name associated with this value.
    public var Name: String
    /// Description associated with this value.
    public var Description: String
    /// CIK associated with this value.
    public var CIK: Int
    /// Exchange associated with this value.
    public var Exchange: String
    /// Currency associated with this value.
    public var Currency: String
    /// Country associated with this value.
    public var Country: String
    /// Sector associated with this value.
    public var Sector: String
    /// Industry associated with this value.
    public var Industry: String
    /// Address associated with this value.
    public var Address: String
    /// Official site associated with this value.
    public var OfficialSite: String
    /// Fiscal year end associated with this value.
    public var FiscalYearEnd: String
    /// Latest quarter associated with this value.
    public var LatestQuarter: String
    /// Market capitalization associated with this value.
    public var MarketCapitalization: Double
    /// EBITDA associated with this value.
    public var EBITDA: Double
    /// Price-to-earnings ratio associated with this value.
    public var PERatio: Double
    /// PEG ratio associated with this value.
    public var PEGRatio: Double
    /// Book value associated with this value.
    public var BookValue: Double
    /// Dividend per share associated with this value.
    public var DividendPerShare: Double
    /// Dividend yield associated with this value.
    public var DividendYield: Double
    /// EPS associated with this value.
    public var EPS: Double
    /// Revenue per share trailing twelve month associated with this value.
    public var RevenuePerShareTTM: Double
    /// Profit margin associated with this value.
    public var ProfitMargin: Double
    /// Operating margin trailing twelve month associated with this value.
    public var OperatingMarginTTM: Double
    /// Return on assets trailing twelve month associated with this value.
    public var ReturnOnAssetsTTM: Double
    /// Return on equity trailing twelve month associated with this value.
    public var ReturnOnEquityTTM: Double
    /// Revenue trailing twelve month associated with this value.
    public var RevenueTTM: Double
    /// Gross profit trailing twelve month associated with this value.
    public var GrossProfitTTM: Double
    /// Diluted epsttm associated with this value.
    public var DilutedEPSTTM: Double
    /// Quarterly earnings growth year-over-year associated with this value.
    public var QuarterlyEarningsGrowthYOY: Double
    /// Quarterly revenue growth year-over-year associated with this value.
    public var QuarterlyRevenueGrowthYOY: Double
    /// Analyst target price associated with this value.
    public var AnalystTargetPrice: Double
    /// Analyst rating strong buy associated with this value.
    public var AnalystRatingStrongBuy: Double
    /// Analyst rating buy associated with this value.
    public var AnalystRatingBuy: Double
    /// Analyst rating hold associated with this value.
    public var AnalystRatingHold: Double
    /// Analyst rating sell associated with this value.
    public var AnalystRatingSell: Double
    /// Analyst rating strong sell associated with this value.
    public var AnalystRatingStrongSell: Double
    /// Trailing price-to-earnings associated with this value.
    public var TrailingPE: Double
    /// Forward price-to-earnings associated with this value.
    public var ForwardPE: Double
    /// Price to sales ratio trailing twelve month associated with this value.
    public var PriceToSalesRatioTTM: Double
    /// Price to book ratio associated with this value.
    public var PriceToBookRatio: Double
    /// Enterprise value to revenue associated with this value.
    public var EVToRevenue: Double
    /// Enterprise value to EBITDA associated with this value.
    public var EVToEBITDA: Double
    /// Beta associated with this value.
    public var Beta: Double
    /// 52 week high associated with this value.
    public var _52WeekHigh: Double
    /// 52 week low associated with this value.
    public var _52WeekLow: Double
    /// 50 day moving average associated with this value.
    public var _50DayMovingAverage: Double
    /// 200 day moving average associated with this value.
    public var _200DayMovingAverage: Double
    /// Shares outstanding associated with this value.
    public var SharesOutstanding: Double
    /// Dividend date associated with this value.
    public var DividendDate: String
    /// Ex dividend date associated with this value.
    public var ExDividendDate: String
    /// Information associated with this value.
    public var Information: String

    enum CodingKeys: String, CodingKey {
        case Symbol, AssetType, Name, Description, CIK, Exchange, Currency, Country, Sector, Industry, Address, OfficialSite, FiscalYearEnd, LatestQuarter, MarketCapitalization, EBITDA, PERatio, PEGRatio, BookValue, DividendPerShare, DividendYield, EPS, RevenuePerShareTTM, ProfitMargin, OperatingMarginTTM, ReturnOnAssetsTTM, ReturnOnEquityTTM, RevenueTTM, GrossProfitTTM, DilutedEPSTTM, QuarterlyEarningsGrowthYOY, QuarterlyRevenueGrowthYOY, AnalystTargetPrice, AnalystRatingStrongBuy, AnalystRatingBuy, AnalystRatingHold, AnalystRatingSell, AnalystRatingStrongSell, TrailingPE, ForwardPE, PriceToSalesRatioTTM, PriceToBookRatio, EVToRevenue, EVToEBITDA, Beta, SharesOutstanding, DividendDate, ExDividendDate, Information
        case _52WeekHigh = "52WeekHigh"
        case _52WeekLow = "52WeekLow"
        case _50DayMovingAverage = "50DayMovingAverage"
        case _200DayMovingAverage = "200DayMovingAverage"
    }

    /// Performs a field-by-field equality check across the decoded Alpha Vantage payload.
    public static func == (lhs: BKV3_InstrumentDetail, rhs: BKV3_InstrumentDetail) -> Bool {
        if lhs.Symbol != rhs.Symbol || lhs.AssetType != rhs.AssetType || lhs.Name != rhs.Name || lhs.Description != rhs.Description || lhs.CIK != rhs.CIK || lhs.Exchange != rhs.Exchange || lhs.Currency != rhs.Currency || lhs.Country != rhs.Country || lhs.Sector != rhs.Sector || lhs.Industry != rhs.Industry {
            return false
        }
        if lhs.Address != rhs.Address || lhs.OfficialSite != rhs.OfficialSite || lhs.FiscalYearEnd != rhs.FiscalYearEnd || lhs.LatestQuarter != rhs.LatestQuarter || lhs.MarketCapitalization != rhs.MarketCapitalization || lhs.EBITDA != rhs.EBITDA || lhs.PERatio != rhs.PERatio || lhs.PEGRatio != rhs.PEGRatio || lhs.BookValue != rhs.BookValue || lhs.DividendPerShare != rhs.DividendPerShare {
            return false
        }
        if lhs.DividendYield != rhs.DividendYield || lhs.EPS != rhs.EPS || lhs.RevenuePerShareTTM != rhs.RevenuePerShareTTM || lhs.ProfitMargin != rhs.ProfitMargin || lhs.OperatingMarginTTM != rhs.OperatingMarginTTM || lhs.ReturnOnAssetsTTM != rhs.ReturnOnAssetsTTM || lhs.ReturnOnEquityTTM != rhs.ReturnOnEquityTTM || lhs.RevenueTTM != rhs.RevenueTTM || lhs.GrossProfitTTM != rhs.GrossProfitTTM || lhs.DilutedEPSTTM != rhs.DilutedEPSTTM {
            return false
        }
        if lhs.QuarterlyEarningsGrowthYOY != rhs.QuarterlyEarningsGrowthYOY || lhs.QuarterlyRevenueGrowthYOY != rhs.QuarterlyRevenueGrowthYOY || lhs.AnalystTargetPrice != rhs.AnalystTargetPrice || lhs.AnalystRatingStrongBuy != rhs.AnalystRatingStrongBuy || lhs.AnalystRatingBuy != rhs.AnalystRatingBuy || lhs.AnalystRatingHold != rhs.AnalystRatingHold || lhs.AnalystRatingSell != rhs.AnalystRatingSell || lhs.AnalystRatingStrongSell != rhs.AnalystRatingStrongSell || lhs.TrailingPE != rhs.TrailingPE || lhs.ForwardPE != rhs.ForwardPE {
            return false
        }
        if lhs.PriceToSalesRatioTTM != rhs.PriceToSalesRatioTTM || lhs.PriceToBookRatio != rhs.PriceToBookRatio || lhs.EVToRevenue != rhs.EVToRevenue || lhs.EVToEBITDA != rhs.EVToEBITDA || lhs.Beta != rhs.Beta || lhs._52WeekHigh != rhs._52WeekHigh || lhs._52WeekLow != rhs._52WeekLow || lhs._50DayMovingAverage != rhs._50DayMovingAverage || lhs._200DayMovingAverage != rhs._200DayMovingAverage || lhs.SharesOutstanding != rhs.SharesOutstanding {
            return false
        }
        return lhs.DividendDate == rhs.DividendDate &&
            lhs.ExDividendDate == rhs.ExDividendDate &&
            lhs.Information == rhs.Information
    }
}
