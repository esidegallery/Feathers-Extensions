package feathers.controls.unthemed
{
    import feathers.controls.PageIndicator;
    import feathers.skins.IStyleProvider;

    public class UnthemedPageIndicator extends PageIndicator
    {
        public static var globalStyleProvider:IStyleProvider;
        override protected function get defaultStyleProvider():IStyleProvider
        {
            return globalStyleProvider;
        }
    }
}