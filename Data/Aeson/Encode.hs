{-# LANGUAGE OverloadedStrings #-}

module Data.Aeson.Encode
    (
      build
    , encode
    ) where

import Blaze.ByteString.Builder
import Blaze.ByteString.Builder.Char.Utf8
import Data.Aeson.Types (JSON(..), Value(..))
import Data.Monoid (mappend, mconcat)
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString.Lazy.Char8 as L
import qualified Data.Map as M
import qualified Data.Text as T
import qualified Data.Vector as V

build :: Value -> Builder
build Null = fromByteString "null"
build (Bool b) = fromByteString $ if b then "true" else "false"
build (Number n) = fromByteString (B.pack (show n))
build (String s) = string s
build (Array v)
    | V.null v = fromByteString "[]"
    | otherwise = fromChar '[' `mappend`
                  build (V.unsafeHead v) `mappend`
                  V.foldr f (fromChar ']') (V.unsafeTail v)
  where f a z = fromChar ',' `mappend` build a `mappend` z
build (Object m) =
    case M.toList m of
      (x:xs) -> fromChar '{' `mappend`
                one x `mappend`
                foldr f (fromChar '}') xs
      _ -> fromByteString "{}"
  where f a z     = fromChar ',' `mappend` one a `mappend` z
        one (k,v) = string k `mappend` fromChar ':' `mappend` build v

string :: T.Text -> Builder
string s = fromChar '"' `mappend` quote s `mappend` fromChar '"'
  where
    quote s = case T.uncons t of
                Just (c,t') -> mconcat [fromText h, fromText (escape c),
                                        quote t']
                Nothing -> fromText h
        where (h,t) = T.break isEscape s
    isEscape c = c == '\"' || c == '\n' || c == '\r' || c == '\t'
    escape '\"' = "\\\""
    escape '\n' = "\\n"
    escape '\r' = "\\r"
    escape '\t' = "\\t"

encode :: JSON a => a -> L.ByteString
encode = toLazyByteString . build . toJSON
{-# INLINE encode #-}